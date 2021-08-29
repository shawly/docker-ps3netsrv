# Docker container for ps3netsrv (or ps3netsvr)
[![Docker Automated build](https://img.shields.io/badge/docker%20build-automated-brightgreen)](https://github.com/shawly/docker-ps3netsrv/actions) [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/shawly/docker-ps3netsrv/Docker)](https://github.com/shawly/docker-ps3netsrv/actions) [![Docker Pulls](https://img.shields.io/docker/pulls/shawly/ps3netsrv)](https://hub.docker.com/r/shawly/ps3netsrv) [![Docker Image Size (tag)](https://img.shields.io/docker/image-size/shawly/ps3netsrv/latest)](https://hub.docker.com/r/shawly/ps3netsrv) [![GitHub Release](https://img.shields.io/github/release/shawly/docker-ps3netsrv.svg)](https://github.com/shawly/docker-ps3netsrv/releases/latest)

This is a Docker container for ps3netsrv (or ps3netsvr).

---

[![ps3netsrv logo](https://images.weserv.nl/?url=raw.githubusercontent.com/shawly/docker-ps3netsrv/master/ps3netsrv-icon.png&w=200)](https://github.com/aldostools/webMAN-MOD)[![ps3netsrv](https://dummyimage.com/400x110/ffffff/575757&text=ps3netsrv)](https://github.com/aldostools/webMAN-MOD)

ps3netsrv for WebMAN-MOD by [aldostools](https://github.com/aldostools). Binaries built from the latest sources.

---
## Table of Content

   * [Docker container for ps3netsrv](#docker-container-for-ps3netsrv)
      * [Table of Content](#table-of-content)
      * [Supported Architectures](#supported-architectures)
      * [Quick Start](#quick-start)
      * [Usage](#usage)
         * [Environment Variables](#environment-variables)
         * [Data Volumes](#data-volumes)
         * [Ports](#ports)
         * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
      * [Docker Compose File](#docker-compose-file)
      * [Docker Image Update](#docker-image-update)
      * [User/Group IDs](#usergroup-ids)
      * [Troubleshooting](#troubleshooting)
      * [Support or Contact](#support-or-contact)

## Supported Architectures

The architectures supported by this image are:

| Architecture | Status |
| :----: | ------ |
| x86-64 | working |
| x86 | untested |
| arm64 | [working](https://github.com/shawly/docker-ps3netsrv/issues/19) |
| armv7 |  untested |
| armhf | working |
| ppc64le | untested |

*I'm declaring the arm images as **untested** because I only own an older first generation RaspberryPi Model B+ I can't properly test the image on other devices, technically it should work on all RaspberryPi models and similar SoCs. While emulating the architecture with qemu works and can be used for testing, I can't guarantee that there will be no issues, just try it.*

*I would be glad if you could [create a small report](https://github.com/shawly/docker-ps3netsrv/issues/new/choose) (choose ARM Compatibility Report) to tell me which device you've tested and if it's working or not.*

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the ps3netsrv docker container with the following command:
```
docker run -d \
    --name=ps3netsrv \
    -p 38008:38008 \
    -v $HOME/ps3games:/games:rw \
    shawly/ps3netsrv
```

Where:
  - `$HOME/ps3games`: This location contains files from your host that need to be accessible by the application.


## Usage

```
docker run [-d] \
    --name=ps3netsrv \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    shawly/ps3netsrv
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in background.  If not set, the container runs in foreground. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/games`| rw | This is the path ps3netsrv will serve to clients. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 38008 | Mandatory | Port used for ps3netsrv. |

### Changing Parameters of a Running Container

As seen, environment variables, volume mappings and port mappings are specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container.  The generic idea is to destroy and
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

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  ps3netsrv:
    image: shawly/ps3netsrv
    environment:
      - TZ: Europe/Berlin
      - USER_ID: 38008
      - GROUP_ID: 38008
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
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

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

First things first, if you have any kind of issue please try to use [the standalone version](https://github.com/aldostools/webMAN-MOD/tree/master/_Projects_/ps3netsrv/bins) of ps3netsrv and try to reproduce the issue. If you have the same issue with the standalone version, it's better to create an issue on the [webMAN-MOD repo](https://github.com/aldostools/webMAN-MOD/issues).

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

The better solution is to override the `ps3netsrv` user's UID and GID, this can be done with the environment variables `USER_ID` and `GROUP_ID`.  
`bob` has the UID 10002 and his `bob` group has the GID 10003 so we need to change the environment variables, like this:
```
docker run -d \
    --name=ps3netsrv \
    -p 38008:38008 \
    -v $HOME/ps3games:/games:rw \
    -e USER_ID=10002 \
    -e GROUP_ID=10003 \
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
If it still doesn't work, you can create a help request with the secret code "SSBoYXZlIHJlYWQsIGZvbGxvd2VkIGFuZCB0cmllZCBldmVyeSB0cm91Ymxlc2hvb3Rpbmcgc3RlcCwgYnV0IGl0IHN0aWxsIGRvZXNuJ3Qgd29yaywgcGxlYXNlIGhlbHAgbWUu".

### The container won't start or webMAN-MOD can't connect to the container

On some systems like Synology NAS systems the default port of ps3netsrv `38008` is in use already, so you simply need to change the host port to something else on the container and change the port within webMAN-MOD's webinterface to the same port.
If the port is not the issue, it might be the latest build of ps3netsrv, try out some older tags of my Docker image as well as [the standalone version](https://github.com/aldostools/webMAN-MOD/tree/master/_Projects_/ps3netsrv/bins) of ps3netsrv.

### webMAN-MOD has access to ps3netsrv but when mounting games they show as corrupted

This is an issue related to the latest UnRAID version, the splitting mechanism of shfs seems to be incompatible with ps3netsrv, take a look at [this issue](https://github.com/aldostools/webMAN-MOD/issues/333), at the bottom you can find some workarounds.
If you do not have UnRAID but some other filesystem please test [the standalone version](https://github.com/aldostools/webMAN-MOD/tree/master/_Projects_/ps3netsrv/bins) of ps3netsrv before creating an issue here.
If the issue also happens with the ps3netsrv standalone on a standard ext4 filesystem, your games are likely to be corrupted or you don't own the files **within** your games folders, check permissions and/or make new backups.

## Support or Contact

Still have trouble with the container or have questions? Please
[create a new issue]. The secret code for help issues is hidden in the troubleshooting steps, read them carefully. If you do not add the help code to your issue, I will have to close it sorry.

[create a new issue]: https://github.com/shawly/docker-ps3netsrv/issues
