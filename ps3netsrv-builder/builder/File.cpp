#include "common.h"
#include "File.h"
#include <stdio.h>
#include <cstring>

File::File()
{
	fd = INVALID_FD;

	is_multipart = index = 0;
	for(int i = 0; i < 64; i++) fp[i] = INVALID_FD;
}

File::~File()
{
	DPRINTF("File destructor.\n");
	
	if (FD_OK(fd))
		this->close();
}

int File::open(const char *path, int flags)
{
	if (FD_OK(fd))
		this->close();
	
	fd = open_file(path, flags);
	if (!FD_OK(fd))
		return -1;

	// multi part
	int plen = strlen(path), flen = plen - 6;
	if(flen < 0)
		is_multipart = 0;
	else
		is_multipart = (strstr(path + flen, ".iso.0") != NULL) || (strstr(path + flen, ".ISO.0") != NULL);

	if(!is_multipart) return 0;

	char *filepath = (char *)malloc(plen + 2); strcpy(filepath, path);

	file_stat_t st;
	fstat_file(fd, &st); part_size = st.file_size;

	is_multipart = 1; // count parts

	for(int i = 1; i < 64; i++)
	{
		filepath[flen + 4] = 0; sprintf(filepath, "%s.%i", filepath, i);

		fp[i] = open_file(filepath, flags);
		if (!FD_OK(fp[i])) break;

		is_multipart++;
	}

	fp[0] = fd; free(filepath);

	return 0;
}

int File::close(void)
{
	int ret = (FD_OK(fd)) ? close_file(fd) : -1; fd = INVALID_FD;

	if(!is_multipart)
		return ret;

	// multi part
	for(int i = 1; i < 64; i++)
	{
		if(FD_OK(fp[i])) close_file(fp[i]); fp[i] = INVALID_FD;
	}

	is_multipart = index = 0;

	return ret;
}

ssize_t File::read(void *buf, size_t nbyte)
{
	if(!is_multipart)
		return read_file(fd, buf, nbyte);

	// multi part
	ssize_t ret2 = 0, ret = read_file(fp[index], buf, nbyte);

	if(ret < nbyte && index < (is_multipart-1))
	{
		void *buf2 = (int8_t*)buf + ret;
		ret2 = read_file(fp[index+1], buf2, nbyte - ret);
	}

	return (ret + ret2);
}

ssize_t File::write(void *buf, size_t nbyte)
{
	if(!is_multipart)
		return write_file(fd, buf, nbyte);

	// multi part
	return write_file(fp[index], buf, nbyte);
}

int64_t File::seek(int64_t offset, int whence)
{
	if(!is_multipart)
		return seek_file(fd, offset, whence);

	// multi part
	index = (int)(offset / part_size);

	return seek_file(fp[index], (offset % part_size), whence);
}

int File::fstat(file_stat_t *fs)
{
	if (!FD_OK(fd)) return -1;

	if(!is_multipart)
		return fstat_file(fd, fs);

	// multi part
	int64_t size = 0;
	file_stat_t statbuf;

	for(int i = 0; i < is_multipart; i++)
	{
		fstat_file(fp[i], &statbuf);
		size += statbuf.file_size;
	}

	int ret = fstat_file(fd, fs); fs->file_size = size;
	return ret;
}
