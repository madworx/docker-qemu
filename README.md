# docker-qemu

Docker image for [QEMU](https://www.qemu.org/), with a few patches to support other [madworx](https://hub.docker.com/u/madworx) docker images.

## Patches

All patches are located under the `patches/` subdirectory.

### `qemu-clientid-bootfile-handling.patch`

NetBSD-specific patch to enable QEMU to use the DHCP `Client-Class` parameter to determine whether to supply the guest the command-line configured BOOTP file, or the hard-coded string `tftp://netbsd.gz` if the client `Class-Id` DHCP option equals `NetBSD:i386:libsa`.

This is used to netboot NetBSD for the [`madworx/netbsd`](https://cloud.docker.com/repository/docker/madworx/netbsd) docker image.

### `qemu-envcmdline.patch`

Enabling QEMU to accept command-line arguments by setting them in the environment variable `QEMU_CMDLINE`.

This is used to make the process name (observable by `ps` and `top`) a bit more readable.

### `qemu-root-path.patch`

Implement the DHCP `Root-Path` option, to enable us to point to from where the guest OS should mount its root filesystem.

### `qemu-alpine-compilefix.patch`

For QEMU 4.0.0 and onwards, `pvh_main.c` needed an explicit cast to `uint64_t` to compile cleanly on Alpine.

## Author

Martin Kjellstrand [martin.kjellstrand@madworx.se]
