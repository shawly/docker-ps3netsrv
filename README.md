# Docker container for ps3netsrv (or ps3netsvr)

[![Build](https://img.shields.io/github/actions/workflow/status/shawly/docker-ps3netsrv/docker-publish.yml?branch=main&label=build&logo=github)](https://github.com/shawly/docker-ps3netsrv/actions/workflows/docker-publish.yml)
[![Release](https://img.shields.io/github/v/release/shawly/docker-ps3netsrv?logo=github)](https://github.com/shawly/docker-ps3netsrv/releases/latest)
[![ps3netsrv](https://img.shields.io/github/v/release/aldostools/ps3netsrv?label=ps3netsrv&logo=playstation)](https://github.com/aldostools/ps3netsrv/releases/latest)
[![License](https://img.shields.io/github/license/shawly/docker-ps3netsrv)](https://github.com/shawly/docker-ps3netsrv/blob/main/LICENSE)

[![Docker Pulls](https://img.shields.io/docker/pulls/shawly/ps3netsrv?logo=docker&logoColor=white)](https://hub.docker.com/r/shawly/ps3netsrv)
[![Image Size](https://img.shields.io/docker/image-size/shawly/ps3netsrv/latest?logo=docker&logoColor=white&label=image%20size)](https://hub.docker.com/r/shawly/ps3netsrv/tags)
[![Docker Version](https://img.shields.io/docker/v/shawly/ps3netsrv?sort=semver&logo=docker&logoColor=white&label=docker)](https://hub.docker.com/r/shawly/ps3netsrv/tags)
[![Stars](https://img.shields.io/github/stars/shawly/docker-ps3netsrv?logo=github)](https://github.com/shawly/docker-ps3netsrv/stargazers)

This is a Docker container for ps3netsrv (or ps3netsvr).

---

[![ps3netsrv logo](https://images.weserv.nl/?url=raw.githubusercontent.com/shawly/docker-ps3netsrv/master/ps3netsrv-icon.png&w=200)](https://github.com/aldostools/ps3netsrv)[![ps3netsrv](https://dummyimage.com/400x110/ffffff/575757&text=ps3netsrv)](https://github.com/aldostools/ps3netsrv)

ps3netsrv for webMAN-MOD by [aldostools](https://github.com/aldostools). Binaries built from the sources of [aldostools/ps3netsrv](https://github.com/aldostools/ps3netsrv).

---

## Table of Content

- [Docker container for ps3netsrv](#docker-container-for-ps3netsrv)
  - [Table of Content](#table-of-content)
  - [Supported tags and respective `Dockerfile` links](#supported-tags-and-respective-dockerfile-links)
  - [Image Variants](#image-variants)
  - [Releases](#releases)
  - [Quick Start](#quick-start)
  - [Usage](#usage)
    - [Environment Variables](#environment-variables)
    - [Health Check](#health-check)
    - [Data Volumes](#data-volumes)
    - [Ports](#ports)
    - [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
  - [Docker Compose File](#docker-compose-file)
  - [Docker Image Update](#docker-image-update)
  - [User/Group IDs](#usergroup-ids)
  - [Troubleshooting](#troubleshooting)
  - [Support or Contact](#support-or-contact)

## Supported tags and respective `Dockerfile` links

<!-- supported tags will be auto updated through workflows! -->
<!-- tags start -->
-	[`20260913`, `20260913-alpine`, `20260913-alpine3.24`, `alpine`, `alpine3.24`, `latest`, `v1`, `v1-alpine`, `v1-alpine3.24`, `v1.12`, `v1.12-alpine`, `v1.12-alpine3.24`, `v1.12.0`, `v1.12.0-alpine`, `v1.12.0-alpine3.24`](https://github.com/shawly/docker-ps3netsrv/blob/main/alpine.Dockerfile)

-	[`20260913-slim`, `20260913-trixie-slim`, `slim`, `trixie-slim`, `v1-slim`, `v1-trixie-slim`, `v1.12-slim`, `v1.12-trixie-slim`, `v1.12.0-slim`, `v1.12.0-trixie-slim`](https://github.com/shawly/docker-ps3netsrv/blob/main/slim.Dockerfile)

-	[`20250501`, `20250501-alpine`, `20250501-alpine3.24`](https://github.com/shawly/docker-ps3netsrv/blob/main/alpine.Dockerfile)

-	[`20250501-slim`, `20250501-trixie-slim`](https://github.com/shawly/docker-ps3netsrv/blob/main/slim.Dockerfile)

-	[`20250216`, `20250216-alpine`, `20250216-alpine3.24`](https://github.com/shawly/docker-ps3netsrv/blob/main/alpine.Dockerfile)

-	[`20250216-slim`, `20250216-trixie-slim`](https://github.com/shawly/docker-ps3netsrv/blob/main/slim.Dockerfile)

-	[`edge`, `edge-alpine`, `edge-alpine3.24`](https://github.com/shawly/docker-ps3netsrv/blob/main/alpine.Dockerfile)

-	[`edge-slim`, `edge-trixie-slim`](https://github.com/shawly/docker-ps3netsrv/blob/main/slim.Dockerfile)
<!-- tags end -->

## Image Variants

Tags follow the convention of the official Docker library images. The ps3netsrv
build date is the version, the base image version is part of the tag, and
`alpine` is the default base so it also owns the bare tags.

| Tag                          | Meaning                                                    |
| ---------------------------- | ---------------------------------------------------------- |
| `20260913-alpine3.23`        | ps3netsrv 20260913 on Alpine 3.23. Fully pinned.            |
| `20260913-alpine`            | Same, but follows whichever Alpine version is current.      |
| `20260913`                   | Same again, `alpine` being the default base.                |
| `alpine3.23`, `alpine`       | Newest ps3netsrv release on that base.                      |
| `latest`                     | Newest ps3netsrv release on the default base.               |
| `20260913-trixie-slim`       | ps3netsrv 20260913 on Debian trixie slim. Fully pinned.     |
| `20260913-slim`, `slim`      | The Debian slim variant, following the current suite.       |
| `v1`, `v1.11`, `v1.11.0`     | This repository's own release tags, with `-slim` variants.  |
| `edge`                       | Built from upstream `master`, rebuilt daily.                |

### Choosing a base

| Base    | Notes                                                                    |
| ------- | ------------------------------------------------------------------------ |
| Alpine  | Default. Smallest image, musl libc.                                       |
| Debian slim | glibc. Try it if a share or filesystem misbehaves under musl.        |

### `shawly/ps3netsrv:edge`

Built from the `master` branch of
[aldostools/ps3netsrv](https://github.com/aldostools/ps3netsrv), rebuilt daily.
Latest upstream code, not considered stable.

## Releases

`latest` tracks the newest ps3netsrv release on its own. It moves within a day
of aldostools publishing, no action needed on this side.

This repository's own `v1.x.y` tags are a separate, deliberate thing, and they
are proposed automatically by
[`.github/workflows/release.yml`](.github/workflows/release.yml).

### How the version is chosen

The bump is derived from conventional commits since the last release, and from
whether upstream moved. Whichever is larger wins.

| Trigger | Bump |
| --- | --- |
| `feat!:` / `fix!:` etc, or a `BREAKING CHANGE:` footer | major |
| `feat:` | minor |
| A new upstream ps3netsrv release | minor |
| `fix:` | patch |
| Only `chore:`, `ci:`, `docs:`, `refactor:` | nothing is released |

Commits are read from the squash-merge subjects on `main`, so the message you
pick when merging a PR is what decides the version. A breaking change has to say
so there.

You can override it by running the workflow manually and picking an explicit
bump instead of `auto`.

### How a release happens

1. Something worth releasing lands on `main`, or upstream publishes.
2. The workflow opens a PR bumping
   [`.github/release.json`](.github/release.json) and regenerating the README
   tag table, then holds it for 14 days. The PR body says what is being cut,
   why, and when it becomes mergeable, and lists any breaking changes.
3. If upstream publishes again inside that window, the PR is rewritten for the
   newer version and the clock restarts.
4. Once the window is up the workflow merges the PR and cuts the GitHub
   release. Merging the PR by hand at any point releases immediately.

`.github/release.json` records which ps3netsrv version the current release
shipped. That is what puts the `v1.x.y` tags on the right line in the table
above, and it is bumped in the release PR itself, so the commit a release tags
already shows the correct versions.

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the ps3netsrv docker container with the following command:

```
docker run -d -t \
    --name=ps3netsrv \
    -p 38008:38008 \
    -v $HOME/ps3games:/games:rw \
    shawly/ps3netsrv
```

Where:

- `$HOME/ps3games`: This location contains files from your host that need to be accessible by the application.

## Usage

```
docker run [-d] -t \
    --name=ps3netsrv \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    shawly/ps3netsrv
```

| Parameter | Description                                                                                                                                              |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| -d        | Run the container in background. If not set, the container runs in foreground.                                                                           |
| -e        | Pass an environment variable to the container. See the [Environment Variables](#environment-variables) section for more details.                         |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container). See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host). See the [Ports](#ports) section for more details.                           |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable). Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable              | Description                                                                                                                         | Default   |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `PUID`             | ID of the user the application runs as. See [User/Group IDs](#usergroup-ids) to better understand when this should be set.          | `1000`    |
| `PGID`            | ID of the group the application runs as. See [User/Group IDs](#usergroup-ids) to better understand when this should be set.         | `1000`    |
| `PS3NETSRV_PORT`      | Port used by ps3netsrv. You only need to change this when using network_mode host, otherwise you can just remap ports using Docker! | `38008`   |
| `PS3NETSRV_WHITELIST` | Whitelist IPs e.g. `192.168.1.*` or `192.168.1.10-192.168.1.200`, this probably only works with network_mode host!                  | ``        |
| `PS3NETSRV_BINARY`    | Which build to run: `mbedtls` (links the system mbedTLS) or `polarssl` (upstream's `Makefile.linux`, bundled AES). Try the other one if decryption misbehaves. | `mbedtls` |
| `UMASK`               | umask applied to the ps3netsrv process.                                                                                            | `022`     |
| `PS3NETSRV_SKIP_CHECKS` | Set to `true` to skip the startup check of the `/games` folder structure and permissions.                                        | `false`   |
| `PS3NETSRV_FIX_PERMISSIONS` | Set to `true` to have the container chown and chmod everything under `/games` on startup. Destructive, off by default.        | `false`   |
| `PS3NETSRV_FOLDER_PERMISSIONS` | Mode applied to directories when `PS3NETSRV_FIX_PERMISSIONS` is `true`.                                                   | `755`     |
| `PS3NETSRV_FILE_PERMISSIONS` | Mode applied to files when `PS3NETSRV_FIX_PERMISSIONS` is `true`.                                                           | `644`     |
| `TZ`                  | [TimeZone] of the container. Timezone can also be set by mapping `/etc/localtime` between the host and the container.               | `Etc/UTC` |

### Health Check

Both images ship a `HEALTHCHECK`, so `docker ps` tells you whether the
container is actually usable rather than merely running:

| State | Meaning |
| --- | --- |
| `healthy` | ps3netsrv owns the listening socket on its port, and `/games` checked out |
| `unhealthy` | the port is not listening, or the `/games` check found problems |

The second half matters: ps3netsrv starts and listens quite happily on a
library it has no permission to read, which looks fine from the outside and is
the usual reason for "it runs but my PS3 sees nothing". `docker inspect` shows
the reason, the container log shows the detail:

```bash
docker inspect --format '{{json .State.Health}}' ps3netsrv
```

The `/games` check runs in parallel with the server, so a large or slow share
never delays startup. While it is still running the container stays healthy on
the strength of the port check alone. Set `PS3NETSRV_SKIP_CHECKS=true` to drop
the `/games` half entirely and health-check only the port.

### Data Volumes

The following table describes data volumes used by the container. The mappings
are set via the `-v` parameter. Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path | Permissions | Description                                       |
| -------------- | ----------- | ------------------------------------------------- |
| `/games`       | rw          | This is the path ps3netsrv will serve to clients. |

### Ports

Here is the list of ports used by the container. They can be mapped to the host
via the `-p` parameter (one per port mapping). Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`. The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port  | Mapping to host | Description              |
| ----- | --------------- | ------------------------ |
| `38008` | Mandatory       | Port used for ps3netsrv. |

### Changing Parameters of a Running Container

As seen, environment variables, volume mappings and port mappings are specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container. The generic idea is to destroy and
re-create the container:

1. Stop the container (if it is running):

```
docker stop ps3netsrv
```

2. Remove the container:

```
docker rm ps3netsrv
```

3. Create/start the container using the `docker run` command, by adjusting
   parameters as needed.

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs. Note that only mandatory network
ports are part of the example.

```yaml
version: "3"
services:
  ps3netsrv:
    image: shawly/ps3netsrv:latest
    restart: unless-stopped
    tty: true
    environment:
      TZ: Europe/Berlin
      PUID: 38008  # change this to the uid of the user that owns your games folder
      PGID: 38008  # change this to the gid of the user that owns your games folder
    ports:
      - "38008:38008"
    volumes:
      - "$HOME/ps3games:/games:rw"
```

## Docker Image Update

If the system on which the container runs doesn't provide a way to easily update
the Docker image, the following steps can be followed:

1. Fetch the latest image:

```
docker pull shawly/ps3netsrv
```

2. Stop the container:

```
docker stop ps3netsrv
```

3. Remove the container:

```
docker rm ps3netsrv
```

4. Start the container using the `docker run` command.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container. For example, the user within the container may not
exists on the host. This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`PUID` and `PGID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:

```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Troubleshooting

First things first, if you have any kind of issue please try to use [the standalone version](https://github.com/aldostools/ps3netsrv/releases) of ps3netsrv and try to reproduce the issue. If you have the same issue with the standalone version, it's better to create an issue on the [ps3netsrv repo](https://github.com/aldostools/ps3netsrv/issues).

### webMAN-MOD can't see or read games from ps3netsrv

There are several possible causes for this issue. I will use the user `bob` who has his backups saved in his home folder under `/home/bob/ps3games` as an example.

#### A. Your folder structure is incorrect

ps3netsrv or rather webMAN-MOD wants to read their games from a certain folder structure, so your volume needs at least the folder `PS3ISO` and `GAMES`.
Therefore it is necessary for bob to create the folders `/home/bob/ps3games/PS3ISO` and `/home/bob/ps3games/GAMES` as well. ISO files go into the `PS3ISO` folder and extracted games in folder format go into the `GAMES` folder. So now `bob` has to mount `/home/bob/ps3games` to the `/games` volume within the container. Like this:

```
docker run -d \
    --name=ps3netsrv \
    -p 38008:38008 \
    -v $HOME/ps3games:/games:rw \
    shawly/ps3netsrv
```

#### B. Your permissions are incorrect

ps3netsrv does not have root permissions within the container, it runs as user `ps3netsrv` which by default has the UID 1000 and the GID 1000.  
There are two solutions for this issue, `bob` could change the ownership of his `ps3games` folder to 1000:1000, which is a bad idea because he will lose access if he does not have the UID 1000.

The better solution is to override the `ps3netsrv` user's UID and GID, this can be done with the environment variables `PUID` and `PGID`.  
`bob` has the UID 10002 and his `bob` group has the GID 10003 so we need to change the environment variables, like this:

```
docker run -d \
    --name=ps3netsrv \
    -p 38008:38008 \
    -v $HOME/ps3games:/games:rw \
    -e PUID=10002 \
    -e PGID=10003 \
    shawly/ps3netsrv
```

#### C. ps3netsrv standalone works but your container doesn't

Make sure to start the ps3netsrv standalone as normal user, not as root user or with sudo. If it works for your root user but not for a non-root user, then go back to troubleshooting step **B**. If the standalone works with both normal users and root but the container doesn't, check the ownership, see the next point **D**.

#### D. All of the above stuff wasn't causing the issue

Alright then, please execute `ls -l path/to/your/ps3games/folder` and `docker exec CONTAINERNAME ls -l /games` (replace **CONTAINERNAME** with the actual name of your container). It should look like this:

```
bob@nas:~$ ls -l /home/bob/ps3games
drwxrwx--- 119 bob bob 119 Mar  4  2019 GAMES
drwxrwx---   7 bob bob   7 Jun 21  2019 PS3ISO
```

```
bob@nas:~$ docker exec ps3netsrv ls -l /games
drwxrwx--- 119 ps3netsrv ps3netsrv 119 Mar  4  2019 GAMES
drwxrwx---   7 ps3netsrv ps3netsrv   7 Jun 21  2019 PS3ISO
```

If the folders aren't owned by ps3netsrv or you are not seeing the GAMES and PS3ISO folders, repeat the troubleshooting steps **A** and **B** above.
If it still doesn't work, you can create a help request with this: "SSBoYXZlIHJlYWQsIGZvbGxvd2VkIGFuZCB0cmllZCBldmVyeSB0cm91Ymxlc2hvb3Rpbmcgc3RlcCwgYnV0IGl0IHN0aWxsIGRvZXNuJ3Qgd29yaywgcGxlYXNlIGhlbHAgbWUu".

### The container won't start or webMAN-MOD can't connect to the container

On some systems like Synology NAS systems the default port of ps3netsrv `38008` is in use already, so you simply need to change the host port to something else on the container and change the port within webMAN-MOD's webinterface to the same port.
If the port is not the issue, it might be the latest build of ps3netsrv, try out some older tags of my Docker image as well as [the standalone version](https://github.com/aldostools/ps3netsrv/releases) of ps3netsrv.

### webMAN-MOD has access to ps3netsrv but when mounting games they show as corrupted

This is an issue related to the latest UnRAID version, the splitting mechanism of shfs seems to be incompatible with ps3netsrv, take a look at [this issue](https://github.com/aldostools/webMAN-MOD/issues/333), at the bottom you can find some workarounds.
If you do not have UnRAID but some other filesystem please test [the standalone version](https://github.com/aldostools/ps3netsrv/releases) of ps3netsrv before creating an issue here.
If the issue also happens with the ps3netsrv standalone on a standard ext4 filesystem, your games are likely to be corrupted or you don't own the files **within** your games folders, check permissions and/or make new backups.

## Support or Contact

Still have trouble with the container or have questions? Please
[create a new issue]. The secret code for help issues is hidden in the troubleshooting steps, read them carefully. If you do not add the help code to your issue, I will have to close it sorry.

[create a new issue]: https://github.com/shawly/docker-ps3netsrv/issues/new/choose
