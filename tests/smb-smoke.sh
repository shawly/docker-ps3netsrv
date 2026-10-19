#!/usr/bin/env bash
# Runs only on a disposable Linux CI host with Docker, Samba and CIFS support.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d /tmp/ps3netsrv-smb.XXXXXXXX)"
PROJECT="ps3netsrv-smb-test-$$"
SMBD_PID=

compose() {
    docker compose --project-name "${PROJECT}" --env-file "${TEST_DIR}/.env" \
        -f "${ROOT}/examples/smb/compose.yaml" "$@"
}

cleanup() {
    status=$?
    if (( status != 0 )); then
        compose logs --tail=100 ps3netsrv || true
        sudo tail -50 "${TEST_DIR}/samba.log" 2>/dev/null || true
    fi
    # Only these test projects own these remote-volume definitions.
    compose down --volumes >/dev/null 2>&1 || true
    PROJECT="${PROJECT}-missing" compose down --volumes >/dev/null 2>&1 || true
    if [[ -n "${SMBD_PID}" ]]; then sudo kill "${SMBD_PID}" 2>/dev/null || true; fi
    # Preserve the isolated fixture for the disposable runner's final cleanup.
    exit "${status}"
}
trap cleanup EXIT

chmod 755 "${TEST_DIR}"
mkdir -p "${TEST_DIR}/library/PS3ISO" "${TEST_DIR}/samba"
chmod -R 755 "${TEST_DIR}/library"
python3 - "${TEST_DIR}/library/PS3ISO/probe.iso" <<'PY'
import pathlib, sys
pathlib.Path(sys.argv[1]).write_bytes(bytes(range(256)) * 512)
PY
chmod 644 "${TEST_DIR}/library/PS3ISO/probe.iso"
sudo useradd --no-create-home --shell /usr/sbin/nologin ps3smbtest
cat >"${TEST_DIR}/smb.conf" <<EOF
[global]
    workgroup = WORKGROUP
    server role = standalone server
    interfaces = 127.0.0.1
    bind interfaces only = yes
    smb ports = 445
    server min protocol = SMB2_10
    log file = ${TEST_DIR}/samba.log
    pid directory = ${TEST_DIR}/samba
    lock directory = ${TEST_DIR}/samba
    state directory = ${TEST_DIR}/samba
    cache directory = ${TEST_DIR}/samba
    private dir = ${TEST_DIR}/samba
[PS3 Games]
    path = ${TEST_DIR}/library
    read only = yes
    valid users = ps3smbtest
EOF
# Public, disposable fixture credentials; deliberately exercise $ and #.
printf '%s\n' 'test$with#hash' 'test$with#hash' | sudo smbpasswd -c "${TEST_DIR}/smb.conf" -s -a ps3smbtest
sudo smbd --foreground --no-process-group --configfile="${TEST_DIR}/smb.conf" &
SMBD_PID=$!
cat >"${TEST_DIR}/.env" <<'EOF'
SMB_SERVER=127.0.0.1
SMB_SHARE=PS3 Games
SMB_USERNAME=ps3smbtest
SMB_PASSWORD='test$with#hash'
SMB_VERSION=3.0
PUID=1000
PGID=1000
PS3NETSRV_HOST_PORT=38008
EOF
chmod 600 "${TEST_DIR}/.env"

# Wait for Samba without logging any credentials or Docker volume metadata.
python3 - <<'PY'
import socket, time
for attempt in range(30):
    try:
        with socket.create_connection(('127.0.0.1', 445), timeout=1):
            break
    except OSError:
        time.sleep(1)
else:
    raise SystemExit('Samba did not start')
PY
compose config --quiet
compose up -d --wait --wait-timeout 90
compose exec -T --user 1000:1000 ps3netsrv test -r /games/PS3ISO/probe.iso
compose exec -T --user 0 ps3netsrv sh -c 'if touch /games/write-test 2>/dev/null; then echo "Unexpected writable share"; exit 1; fi'
python3 "${ROOT}/tests/smb-read.py" 38008

compose stop
compose up -d --wait --wait-timeout 90
python3 "${ROOT}/tests/smb-read.py" 38008
echo 'PASS: read-only mount, application UID access and automatic remount after stop/start'

if SMB_SHARE=does-not-exist PROJECT="${PROJECT}-missing" compose up -d; then
    echo 'Unexpected successful startup with a missing share' >&2
    exit 1
fi
echo 'PASS: missing SMB share prevents container startup'
