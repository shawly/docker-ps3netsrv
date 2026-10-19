# Serve games from an SMB share

This example uses Docker's built-in `local` volume driver to mount an SMB/CIFS
share at `/games`. Docker mounts the share before starting ps3netsrv, so the
existing Alpine or Debian slim image works without changes. The application
container does not need `privileged`, `SYS_ADMIN`, or an SMB client package.

## Requirements

- A rootful Docker Engine on Linux with the Compose plugin.
- CIFS support in the **Docker host's kernel**, and network access from that
  host to the SMB server (normally TCP 445). With a remote Docker context,
  this means the daemon host, not the machine running the Compose command.
- An SMB account with read access to the library. Prefer a dedicated read-only
  account. This example does not enable SMB1 or guest authentication.

Rootless Docker cannot perform this kernel mount. Docker Desktop and NAS app
runtimes may impose additional mount restrictions; this example targets a Linux
Docker Engine. On TrueNAS, when the library is already a local dataset, use the
regular bind mount example instead and grant the container's UID/GID access in
the dataset ACL. TrueNAS CORE cannot run Linux Docker containers natively.

The share root should contain the content folders, for example:

```text
PS3/                 # SMB share name
├── PS3ISO/
│   └── Example.iso
├── GAMES/
└── PSXISO/
```

## Start

Run from this directory:

```sh
cp .env.example .env
chmod 600 .env
# Edit .env with your server, share and credentials.
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs --tail=100 ps3netsrv
```

`SMB_SERVER` is a hostname or IPv4 address, without a `smb://` prefix.
`SMB_SHARE` is the share name, such as `PS3`, without leading slashes. The `addr`
option lets Docker resolve a hostname before mounting. `SMB_DOMAIN` defaults to
`WORKGROUP`; set it to the account's domain when required. `SMB_VERSION` defaults
to `3.0`; use `3.1.1` or `2.1` if appropriate for your server. Authentication and
share ACLs still apply; `PUID`/`PGID` and the mode options only control the local
view of the files. `forceuid`/`forcegid` ensure that view matches the container
identity even when the server supplies ownership information.

Both the CIFS mount and the container volume are read-only. `nocopy` prevents
Docker from populating the remote share from the image. Do not enable
`PS3NETSRV_FIX_PERMISSIONS` for this share. Features that write to `/games` are
unavailable with this example.

In webMAN MOD, enable a network server in **Scan for content**, enter the Docker
host's LAN address and `PS3NETSRV_HOST_PORT` (default `38008`), save, then refresh
the game list and XMB. Use the host address, not the container address or the
SMB server address, unless they are the same machine. Keep NETISO's published
port restricted to your trusted LAN; it is not an authenticated public service.

## Credentials

Compose interpolates `.env` values into the volume options. Use single-quoted
values to preserve characters such as `$` and `#`. CIFS options are a
comma-separated string: **do not use commas or line breaks in these values**.
For credentials that require them, mount the share on the host using
`mount.cifs` and a protected credentials file, then bind mount it into `/games`.

The password is stored in Docker's volume metadata and is visible to users with
Docker access via `docker volume inspect`. `docker compose config` without
`--quiet` also prints the interpolated password. Do not publish this output,
commit `.env`, or attach it to bug reports. The password is not passed into the
ps3netsrv container's environment by this example.

Docker's local driver invokes the kernel mount operation directly; it does not
run `mount.cifs`. Its `o` options cannot use a `credentials=/path/to/file` option
as a substitute for the password. Docker secrets inside the application
container are also unavailable to the daemon when it mounts the volume.

## Startup, outages and changes

Docker establishes the volume mount before starting the container, including on
normal container restarts. If the SMB server is unavailable or authentication
fails, the container cannot start. `restart: unless-stopped` is not a retry loop
for a failed initial volume mount: restore the share and run
`docker compose up -d` again. During a server outage, CIFS reconnect behavior is
handled by the host kernel; an active game may stall or fail and need remounting
in webMAN after service returns.

Existing named volumes retain their driver options. Changing `.env` and only
restarting the container will not update those options. After changing server,
share, credentials, SMB version, or UID/GID, run from this directory:

```sh
docker compose down
docker volume rm ps3netsrv-smb_games
docker compose up -d
```

This removes this example's Docker volume definition, not files from the SMB
share. It interrupts active streaming. If you changed the Compose project name
with `-p` or `COMPOSE_PROJECT_NAME`, replace `ps3netsrv-smb_games` with that
project's volume name. Do not remove unrelated volumes.

If mounting is denied, check host CIFS support, the share name, credentials, SMB
version, and the host's mount/security policy. If the mount succeeds but games
are absent, check the folder layout and the SMB account's read permissions.

## Automated verification

The [SMB example workflow](../../.github/workflows/smb-example.yml) runs this
Compose file against a temporary Samba server on a disposable Linux runner,
using both Alpine and Debian slim images. It checks an actual CIFS mount,
read access as the application user, rejected writes, NETISO reads at multiple
offsets, stop/start recovery, and failure to start with a missing share. Test
credentials include literal `$` and `#` characters.

The fixture is synthetic data, not a playable game. This verifies the storage
and network path; game compatibility and behavior on real PS3 hardware still
depend on webMAN, firmware, the game image, and your network.

See [Docker's CIFS volume documentation](https://docs.docker.com/engine/storage/volumes/#create-cifssamba-volumes)
and [webMAN's PS3 NET Server guide](https://github.com/aldostools/webMAN-MOD/wiki/~-PS3-NET-Server).
