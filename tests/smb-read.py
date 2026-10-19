#!/usr/bin/env python3
"""Read a synthetic fixture over NETISO, without requiring a PS3 or game dump."""
import socket
import struct
import sys


def receive(sock, length):
    data = bytearray()
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            raise RuntimeError("NETISO closed the connection before the read completed")
        data.extend(chunk)
    return bytes(data)


with socket.create_connection(("127.0.0.1", int(sys.argv[1])), timeout=10) as sock:
    sock.settimeout(10)
    name = b"/PS3ISO/probe.iso"
    sock.sendall(struct.pack(">HH12x", 0x1224, len(name)) + name)
    size, _ = struct.unpack(">qQ", receive(sock, 16))
    assert size == 131072, f"Unexpected fixture size: {size}"
    for offset in (0, 8192, 130816):
        sock.sendall(struct.pack(">HHIQ", 0x1225, 0, 256, offset))
        assert receive(sock, 256) == bytes(range(256)), f"Read mismatch at {offset}"
print("PASS: NETISO open and random-offset reads from the SMB volume")
