/* "open-sourced" by spender
   reversed from the provided binary in a couple hours
   added options to daemonize and run as a specific user/group
*/

#define _LARGEFILE64_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <dirent.h>
#include <netinet/in.h>
#include <netdb.h>
#include <endian.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <pwd.h>
#include <grp.h>
#include <errno.h>
#include <sys/signal.h>

typedef unsigned long long u64;

#define DEFAULT_PORT 38008
#define LOWEST_PORT 1024
#define NUM_THREADS 3
#define BUFFER_SIZE (4 * 1024 * 1024)
#define CHUNK_SIZE 2048

#define FALSE 0
#define TRUE 1

char rootpath[PATH_MAX+1];

struct param {
	int fd;
	int read_fd;
	int write_fd;
	DIR *dir_fd;
	char *dirname;
	char *buffer;
	int connected;
	int unused;
	unsigned int client_ip;
	pthread_t thread;
};

struct command {
	unsigned short code;
	unsigned short size;
	unsigned int count;
	u64 offset;
} __attribute__((packed));

struct file_info {
	u64 size;
	u64 mtime;
	u64 ctime;
	u64 atime;
	unsigned int mode;
} __attribute__((packed));

struct file_reply_with_namelen {
	u64 size;
	u64 mtime;
	u64 ctime;
	u64 atime;
	unsigned short namelen;
	unsigned char is_dir;
} __attribute__((packed));

struct file_reply_short {
	u64 size;
	unsigned short namelen;
	unsigned char is_dir;
} __attribute__((packed));

struct file_reply {
	u64 size;
	u64 mtime;
	u64 ctime;
	u64 atime;
	unsigned char is_dir;
} __attribute__((packed));

u64 htonll(u64 val) {
#if __BYTE_ORDER == __LITTLE_ENDIAN
	return htonl(val >> 32) | ((unsigned long long)htonl((unsigned long)val) << 32);
#else
	return val;
#endif
}
u64 ntohll(u64 val) {
	return htonll(val);
}

struct param thread_params[NUM_THREADS];

char *absolute_path(char *path);

int get_file_info(char *path, struct file_info *info)
{
	int ret;
	struct stat64 st;

	ret = stat64(path, &st);
	if (ret < 0)
		return ret;
	info->size = st.st_size;
	info->mtime = st.st_mtime;
	info->ctime = st.st_ctime;
	info->atime = st.st_atime;
	info->mode = st.st_mode;

	return 0;
}

int get_fd_info(int fd, struct file_info *info)
{
	int ret;
	struct stat64 st;

	ret = fstat64(fd, &st);
	if (ret < 0)
		return ret;
	info->size = st.st_size;
	info->mtime = st.st_mtime;
	info->ctime = st.st_ctime;
	info->atime = st.st_atime;
	info->mode = st.st_mode;

	return 0;
}

void *drop_client(struct param *client)
{
	shutdown(client->fd, SHUT_RDWR);
	close(client->fd);
	if (client->read_fd >= 0)
		close(client->read_fd);
	if (client->write_fd >= 0)
		close(client->write_fd);
	if (client->dir_fd)
		closedir(client->dir_fd);
	if (client->dirname)
		free(client->dirname);
	free(client->buffer);
	return memset(client, 0, sizeof(*client));
}

int setup_new_client(struct param *client)
{
	memset(client, 0, sizeof(*client));
	client->buffer = malloc(BUFFER_SIZE);
	if (client->buffer == NULL)
		return -1;
	client->read_fd = -1;
	client->write_fd = -1;
	client->dir_fd = 0;
	client->dirname = NULL;
	client->connected = 1;

	return 0;
}

int init_socket(unsigned short port)
{
	int fd;
	unsigned int optval;
	struct sockaddr_in addr;
	struct sockaddr *sock = (struct sockaddr *)&addr;

	fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (fd < 0)
		return fd;
	optval = 1;
	if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) < 0) {
		close(fd);
		return -1;
	}
	sock->sa_family = AF_INET;
	addr.sin_port = htons(port);
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	memset(&addr.sin_zero, 0, sizeof(addr.sin_zero));
	if (bind(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr)) < 0) {
		close(fd);
		return -1;
	}
	if (listen(fd, 1) < 0) {
		close(fd);
		return -1;
	}

	return fd;
}

ssize_t recv_bytes(int fd, void *buf, size_t n)
{
	return recv(fd, buf, n, MSG_WAITALL);
}

int get_file_size(struct param *params, struct command *cmd)
{
	struct file_info finfo;
	u64 reply[2];
	unsigned int size = ntohs(cmd->size);
	char *path = malloc(size + 1);
	ssize_t bytes_sent;
	int error = 0;

	if (path == NULL)
		return -1;
	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	if (params->read_fd >= 0) {
		close(params->read_fd);
		params->read_fd = -1;
	}
	params->read_fd = open64(path, O_RDONLY);
	if (params->read_fd < 0)
		error = 1;
	if (!error && (get_fd_info(params->read_fd, &finfo) >= 0)) {
		reply[0] = htonll(finfo.size);
		reply[1] = htonll(finfo.mtime);
	} else
		error = 1;
	if (error) {
		reply[0] = htonll(-1LL);
		reply[1] = htonll(0LL);
	}		
	free(path);
	bytes_sent = send(params->fd, reply, sizeof(reply), 0);
	if (bytes_sent != sizeof(reply))
		return -1;
	return 0;
}

int get_file_stat(struct param *params, struct command *cmd)
{
	struct file_info finfo;
	struct file_reply reply;
	unsigned int size = ntohs(cmd->size);
	char *path = malloc(size + 1);

	if (path == NULL)
		return -1;
	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	if (get_file_info(path, &finfo) < 0) {
		reply.size = htonll(-1LL);
	} else {
		if (S_ISDIR(finfo.mode)) {
			reply.size = htonll(0);
			reply.is_dir = 1;
		} else {
			reply.size = htonll(finfo.size);
			reply.is_dir = 0;
		}
		reply.mtime = htonll(finfo.mtime);
		reply.ctime = htonll(finfo.ctime);
		reply.atime = htonll(finfo.atime);
	}
	free(path);

	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

int open_file_for_writing(struct param *params, struct command *cmd)
{
	unsigned int size = ntohs(cmd->size);
	char *path = malloc(size + 1);
	unsigned int reply;

	if (path == NULL)
		return -1;
	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	if (params->write_fd >= 0) {
		close(params->write_fd);
		params->write_fd = -1;
	}
	params->write_fd = open64(path, O_EXCL | O_WRONLY);
	if (params->write_fd < 0)
		reply = htonl(-1);
	else
		reply = htonl(0);
	free(path);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

int open_dir(struct param *params, struct command *cmd)
{
	unsigned int size = ntohs(cmd->size);
	char *path = malloc(size + 1);
	unsigned int reply;

	if (path == NULL)
		return -1;
	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	if (params->dir_fd >= 0) {
		closedir(params->dir_fd);
		params->dir_fd = NULL;
	}
	if (params->dirname)
		free(params->dirname);
	params->dirname = NULL;
	params->dir_fd = opendir(path);
	if (params->dir_fd) {
		params->dirname = path;
		reply = htonl(0);
	} else
		reply = htonl(-1);
	if (params->dirname == NULL)
		free(path);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

int read_file(struct param *params, struct command *cmd)
{
	off64_t offset = ntohll(cmd->offset);
	off64_t ret;
	unsigned int bytes_to_read = ntohl(cmd->count);
	if (params->read_fd < 0)
		return -1;
	ret = lseek64(params->read_fd, offset, SEEK_SET);
	if (ret == (off64_t)-1)
		return -1;
	while (bytes_to_read) {
		unsigned int nbytes;
		if (bytes_to_read >= BUFFER_SIZE)
			nbytes = BUFFER_SIZE;
		else
			nbytes = bytes_to_read;
		if (read(params->read_fd, params->buffer, nbytes) != nbytes)
			return -1;
		if (send(params->fd, params->buffer, nbytes, 0) != nbytes)
			return -1;
		bytes_to_read -= nbytes;
	}

	return 0;
}

int read_short_file(struct param *params, struct command *cmd)
{
	off64_t offset = ntohll(cmd->offset);
	off64_t ret;
	unsigned int bytes_to_read = ntohl(cmd->count);
	ssize_t bytes_read;
	unsigned int reply;

	if (params->read_fd < 0)
		bytes_read = -1;
	else {
		if (bytes_to_read > BUFFER_SIZE)
			bytes_read = -1;
		else {
			ret = lseek64(params->read_fd, offset, SEEK_SET);
			if (ret == (off64_t)-1)
				bytes_read = -1;
			else
				bytes_read = read(params->read_fd, params->buffer, bytes_to_read);
		}
	}
	reply = htonl(bytes_read);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;
	if (bytes_read > 0 && (send(params->fd, params->buffer, bytes_read, 0) != bytes_read))
		return -1;

	return 0;
}

int custom_read_file(struct param *params, struct command *cmd)
{
	off64_t offset = 2352 * ntohl(cmd->count);
	unsigned int chunks = ntohl(*(unsigned int *)&cmd->offset);
	unsigned int i;
	char *buf;

	if ((chunks * CHUNK_SIZE) > BUFFER_SIZE)
		return -1;

	buf = params->buffer;
	for (i = 0; i < chunks; i++) {
		lseek64(params->read_fd, offset + 24, SEEK_SET);
		if (read(params->read_fd, buf, CHUNK_SIZE) != CHUNK_SIZE)
			return -1;
		buf += CHUNK_SIZE;
		offset += 2352LL;
	}
	if (send(params->fd, params->buffer, chunks * CHUNK_SIZE, 0) != (chunks * CHUNK_SIZE))
		return -1;

	return 0;
}

int write_to_file(struct param *params, struct command *cmd)
{
	ssize_t bytes_to_write = ntohl(cmd->count);
	ssize_t bytes_written;
	unsigned int reply;
	if (params->write_fd >= 0) {
		if (bytes_to_write > BUFFER_SIZE)
			return -1;
		if (bytes_to_write && recv_bytes(params->fd, params->buffer, bytes_to_write) != bytes_to_write)
			return -1;
		bytes_written = write(params->fd, params->buffer, bytes_to_write);
		if (bytes_written < 0)
			bytes_written = -1;
	} else
		bytes_written = -1;

	reply = htonl(bytes_written);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;
	return 0;
}

int delete_file(struct param *params, struct command *cmd)
{
	unsigned int size = ntohs(cmd->size);
	char *path = malloc(size + 1);
	unsigned int reply;

	if (path == NULL)
		return -1;

	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	reply = unlink(path);
	reply = htonl(reply);
	free(path);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

int make_dir(struct param *params, struct command *cmd)
{
	unsigned int size = cmd->size;
	char *path = malloc(size + 1);
	unsigned int reply;

	if (path == NULL)
		return -1;

	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	reply = mkdir(path, 0777);
	reply = htonl(reply);
	free(path);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

int remove_dir(struct param *params, struct command *cmd)
{
	unsigned int size = cmd->size;
	char *path = malloc(size + 1);
	unsigned int reply;

	if (path == NULL)
		return -1;

	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	reply = rmdir(path);
	reply = htonl(reply);
	free(path);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

u64 accumulate_sizes(char *path)
{
	u64 total_size = 0ULL;
	DIR *dirp;
	struct dirent64 *dir;
	int stop;
	char *newname;
	struct file_info finfo;

	dirp = opendir(path);
	if (dirp == NULL)
		return ~0ULL;
	do {
		dir = readdir64(dirp);
		if (!dir)
			break;
		if (!strcmp(dir->d_name, ".") || !strcmp(dir->d_name, "..") || dir->d_name[0] == '\0') {
			stop = 0;
			continue;
		}
		newname = alloca(strlen(path) + strlen(dir->d_name) + 2);
		sprintf(newname, "%s/%s", path, dir->d_name);
		if (get_file_info(newname, &finfo) < 0) {
			total_size = ~0ULL;
			stop = 1;
			continue;
		}
		if (S_ISDIR(finfo.mode)) {
			u64 tmp = accumulate_sizes(newname);
			if (tmp == ~0ULL) {
				total_size = tmp;
				stop = 1;
				continue;
			}
			total_size += tmp;
		} else {
			if (S_ISREG(finfo.mode))
				total_size += finfo.size;
		}
		stop = 2;
	} while (stop == 0 || stop == 2);
	closedir(dirp);

	return total_size;
}

int get_directory_size(struct param *params, struct command *cmd)
{
	unsigned int size = cmd->size;
	char *path = malloc(size + 1);
	u64 reply;

	if (path == NULL)
		return -1;

	path[size] = '\0';
	if (recv_bytes(params->fd, path, size) != size) {
		free(path);
		return -1;
	}
	path = absolute_path(path);
	if (path == NULL)
		return -1;
	reply = accumulate_sizes(path);
	reply = htonll(reply);
	free(path);
	if (send(params->fd, &reply, sizeof(reply), 0) != sizeof(reply))
		return -1;

	return 0;
}

int list_directory_entry(struct param *params, struct command *cmd, int shortmode)
{
	struct file_info finfo;
	struct file_reply_short reply_short;
	struct file_reply_with_namelen reply_long;
	struct dirent64 *dir;
	char *newname;

	if (shortmode == 1)
		memset(&reply_short, 0, sizeof(reply_short));
	else
		memset(&reply_long, 0, sizeof(reply_long));
	if (!params->dir_fd || !params->dirname) {
		if (shortmode == 1)
			reply_short.size = htonll(-1LL);
		else
			reply_long.size = htonll(-1LL);		
		goto reply;
	}
	do {
		dir = readdir64(params->dir_fd);
	} while (dir && (!strcmp(dir->d_name, ".") || !strcmp(dir->d_name, "..") || strlen(dir->d_name) > PATH_MAX));
	if (!dir) {
		closedir(params->dir_fd);
		free(params->dirname);
		params->dir_fd = NULL;
		params->dirname = NULL;
		if (shortmode == 1)
			reply_short.size = htonll(-1LL);
		else
			reply_long.size = htonll(-1LL);
		goto reply;
	}
	newname = malloc(strlen(params->dirname) + strlen(dir->d_name) + 2);
	if (newname == NULL) {
		printf("Memory allocation error\n");
		exit(-1);
	}
	sprintf(newname, "%s/%s", params->dirname, dir->d_name);
	if (get_file_info(newname, &finfo) < 0) {
		closedir(params->dir_fd);
		free(params->dirname);
		params->dir_fd = NULL;
		params->dirname = NULL;
		if (shortmode == 1)
			reply_short.size = htonll(-1LL);
		else
			reply_long.size = htonll(-1LL);
		free(newname);
		goto reply;
	}
	free(newname);
	if (S_ISDIR(finfo.mode)) {
		if (shortmode == 1) {
			reply_short.size = htonll(0);
			reply_short.is_dir = 1;
		} else {
			reply_long.size = htonll(0);
			reply_long.is_dir = 1;
		}
	} else {
		if (shortmode == 1) {
			reply_short.size = htonll(finfo.size);
			reply_short.is_dir = 0;
		} else {
			reply_long.size = htonll(finfo.size);
			reply_long.is_dir = 0;
		}
	}
	if (shortmode == 1)
		reply_short.namelen = htons(strlen(dir->d_name));
	else {
		reply_long.namelen = htons(strlen(dir->d_name));
		reply_long.atime = htonll(finfo.atime);
		reply_long.ctime = htonll(finfo.ctime);
		reply_long.mtime = htonll(finfo.mtime);
	}
reply:
	if (shortmode == 1) {
		if (send(params->fd, &reply_short, sizeof(reply_short), 0) != sizeof(reply_short))
			return -1;
	} else {
		if (send(params->fd, &reply_long, sizeof(reply_long), 0) != sizeof(reply_long))
			return -1;
	}
	if (((shortmode == 1 && reply_short.size != htonll(-1LL)) ||
	     (shortmode == 2 && reply_long.size != htonll(-1LL))) &&
	     (send(params->fd, dir->d_name, strlen(dir->d_name), 0) != (ssize_t)strlen(dir->d_name)))
		return -1;

	return 0;
}

char *absolute_path(char *path)
{
	char *p, *p2;

	if (path[0] != '/')
		goto out;

	p = path;
	while (1) {
		p2 = strstr(p, "..");
		if (!p2) {
			char *newname;

			newname = malloc(strlen(rootpath) + strlen(path) + 1);
			if (newname == NULL) {
				printf("Memory allocation error\n");
				exit(-1);
			}
			sprintf(newname, "%s%s", rootpath, path);
			free(path);
			return newname;
		}
		if (p2 && strlen(p2) > 1 && (*(p2 - 1) == '/' || *(p2 - 1) == '\\') &&
		    (p2[2] == '\0' || p2[2] == '/' || p2[2] == '\\'))
			break;
		p = p + 2;
	}
out:
	free(path);
	return NULL;
}

void *command_handler(void *arg)
{
	struct param *params = (struct param *)arg;
	struct command cmd;
	unsigned short code;
	int error = 0;

	while (!error) {
		if (recv_bytes(params->fd, &cmd, sizeof(cmd)) != sizeof(cmd))
			break;
		code = ntohs(cmd.code);

		switch (code) {
		case 0x1224:
			error = get_file_size(params, &cmd);
			break;
		case 0x1225:
			error = read_file(params, &cmd);
			break;
		case 0x1226:
			error = custom_read_file(params, &cmd);
			break;
		case 0x1227:
			error = read_short_file(params, &cmd);
			break;
		case 0x1228:
			error = open_file_for_writing(params, &cmd);
			break;
		case 0x1229:
			error = write_to_file(params, &cmd);
			break;
		case 0x122a:
			error = open_dir(params, &cmd);
			break;
		case 0x122b:
			// short mode
			error = list_directory_entry(params, &cmd, 1);
			break;
		case 0x122c:
			error = delete_file(params, &cmd);
			break;
		case 0x122d:
			error = make_dir(params, &cmd);
			break;
		case 0x122e:
			error = remove_dir(params, &cmd);
			break;
		case 0x122f:
			// long mode
			error = list_directory_entry(params, &cmd, 2);
			break;
		case 0x1230:
			error = get_file_stat(params, &cmd);
			break;
		case 0x1231:
			error = get_directory_size(params, &cmd);
			break;
		default:
			error = -1;
			break;
		}
	}

	printf("Dropping client...\n");
	drop_client(params);

	return NULL;
}

void usage(char *base)
{
	printf("Usage: %s [-d] [-u user] [-g group] [-p port] [-w whitelist] rootdirectory\n"
		"Default port: %d\n"
		"Whitelist: x.x.x.x, where x is 0-255 or * (e.g 192.168.1.* to allow only connections from 192.168.1.0-192.168.1.255)\n",
		base, DEFAULT_PORT);
	exit(-1);
}

int main(int argc, char *argv[])
{
	int ret;
	int i;
	unsigned int port = DEFAULT_PORT;
	unsigned int daemonize = 0;
	unsigned int uid = getuid();
	unsigned int gid = getgid();
	unsigned int orig_gid = gid;
	struct passwd *pwd;
	struct group *grp;
	unsigned int iprange_low = 0;
	unsigned int iprange_high = 0;
	int client_fd = -1;
	int server_fd;
	int opt;

	if (argc < 2)
		usage(argv[0]);

	while ((opt = getopt(argc, argv, "du:g:p:w:")) != -1) {
		switch (opt) {
		case '\x01':
			printf("optarg=%s\n", optarg);
			break;
		case 'd':
			daemonize = 1;
			break;
		case 'u':
			pwd = getpwnam(optarg);
			if (pwd == NULL) {
				if (errno == EPERM) {
					printf("You don't have sufficient privileges to run as a different user.\n");
					exit(-1);
				} else {
					printf("User \"%s\" not found.\n", optarg);
					exit(-1);
				}
			}
			uid = pwd->pw_uid;
			break;
		case 'g':
			grp = getgrnam(optarg);
			if (grp == NULL) {
				if (errno == EPERM) {
					printf("You don't have sufficient privileges to run as a different group.\n");
					exit(-1);
				} else {
					printf("Group \"%s\" not found.\n", optarg);
					exit(-1);
				}
			}
			gid = grp->gr_gid;
			break;
		case 'p':
			if (sscanf(optarg, "%u", &port) != 1) {
				printf("Wrong port specified.\n");
				exit(-1);
			}
			if (port < LOWEST_PORT || port > 65535) {
				printf("Port must be in %d-65535 range.\n", LOWEST_PORT);
				exit(-1);
			}
			break;
		case 'w': {
			char *ip = optarg;
			int j;
			unsigned int octet;
			int is_wildcard;

			for (j = 3; j >= 0; j--) {
				is_wildcard = FALSE;
				if (sscanf(ip, "%u", &octet) == 1) {
					if (octet > 256) {
						printf("Wrong whitelist format.\n");
						exit(-1);
					}
				} else {
					// only allow wildcard in the last position
					if (j && (ip[0] != '*' || ip[1] != '.')) {
						printf("Wrong whitelist format.\n");
						exit(-1);
					} else if (strcmp(ip, "*")) {
						printf("Wrong whitelist format.\n");
						exit(-1);
					}
					is_wildcard = TRUE;
				}
				if (is_wildcard)
					iprange_high |= 255 << (8 * j);
				else {
					iprange_low |= octet << (8 * j);
					iprange_high |= octet << (8 * j);
				}
				if (j) {
					ip = strchr(ip, '.');
					if (ip == NULL) {
						printf("Wrong whitelist format.\n");
						exit(-1);
					}
					ip++;
				}
			}
			}
			break;
		default:
			usage(argv[0]);
		}
	}

	if ((optind + 1) != argc) {
		usage(argv[0]);
	}

	if (strlen(argv[optind]) > PATH_MAX) {
		printf("Directory name too long!");
		exit(-1);
	}

	strcpy(rootpath, argv[optind]);

	for (i = strlen(rootpath) - 1; i >= 0 && (rootpath[i] == '/' || rootpath[i] == '\\'); i--)
		rootpath[i] = '\0';

	if (rootpath[0] == '\0') {
		printf("/ can't be specified as root directory!\n");
		exit(-1);
	}

	if (chdir(rootpath)) {
		printf("Unable to change to rootpath: %s\n", strerror(errno));
		exit(-1);
	}

	if (daemonize) {
		int pid = fork();
		if (pid > 0)
			exit(0);
		else if (pid < 0) {
			printf("Unable to daemonize.\n");
			exit(-1);
		} else {
			int i;
			setsid();
			for (i = getdtablesize(); i >= 0; i--)
				close(i);
			i = open("/dev/null", O_RDWR);
			dup(i);
			dup(i);
			signal(SIGCHLD, SIG_IGN);
			signal(SIGTSTP, SIG_IGN);
			signal(SIGTTOU, SIG_IGN);
			signal(SIGTTIN, SIG_IGN);
		}
	}

	if (setgid(gid) || gid != getgid() || (orig_gid != gid && setgroups(0, NULL))) {
		printf("Unable to change group.\n");
		exit(-1);
	}

	if (setuid(uid) || uid != getuid()) {
		printf("Unable to change user.\n");
		exit(-1);
	}

	server_fd = init_socket(port);
	if (server_fd < 0) {
		printf("Error in initialization.\n");
		exit(-1);
	}
	memset(&thread_params, 0, sizeof(thread_params));
	printf("Waiting for client...\n");
	while (1) {
		struct sockaddr_in addr;
		int k;
		while (1) {
			while (1) {
				unsigned addr_size = sizeof(addr);
				unsigned int tmp_ip;

				client_fd = accept(server_fd, (struct sockaddr *)&addr, &addr_size);
				if (client_fd < 0) {
					printf("Network error.\n");
					return 0;
				}
				for (k = 0; k < NUM_THREADS; k++) {
					if (thread_params[k].connected && thread_params[k].client_ip == addr.sin_addr.s_addr)
						break;
				}
				if (k != NUM_THREADS) {
					shutdown(thread_params[k].fd, SHUT_RDWR);
					close(thread_params[k].fd);
					pthread_join(thread_params[k].thread, NULL);
					printf("Reconnection from %s\n", inet_ntoa(addr.sin_addr));
					goto connection;
				}
				if (!iprange_low)
					break;
				tmp_ip = ntohl(addr.sin_addr.s_addr);
				if (tmp_ip >= iprange_low && tmp_ip <= iprange_high)
					break;
				printf("Rejected connection from %s (not in whitelist)\n", inet_ntoa(addr.sin_addr));
				close(client_fd);
			}

			for (k = 0; k < NUM_THREADS; k++) {
				if (!thread_params[k].connected)
					break;
			}
			if (k != NUM_THREADS)
				break;
			printf("Too many connections! (rejected client: %s)\n", inet_ntoa(addr.sin_addr));
			close(client_fd);
		}
		printf("Connection from %s\n", inet_ntoa(addr.sin_addr));
connection:
		if (setup_new_client(&thread_params[k]))
			break;
		thread_params[k].fd = client_fd;
		thread_params[k].client_ip = addr.sin_addr.s_addr;
		pthread_create(&thread_params[k].thread, NULL, &command_handler, (void *)&thread_params[k]);
	}
	printf("System seems low in resources.\n");
out:
	return ret;
}
