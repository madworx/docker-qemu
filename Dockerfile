FROM alpine:3.16 AS build-qemu

LABEL maintainer="Martin Kjellstrand [https://github.com/madworx]"

ARG QEMU_RELEASE="v7.1.0"

ARG QEMU_BUILD_PKGS="xen-dev curl-dev libcap-dev bzip2-dev git-email \
                     bash ninja libaio-dev snappy-dev libseccomp-dev \
                     build-base sed libssh2-dev jpeg-dev ncurses-dev \
                     libnfs-dev flex sdl2-dev lzo-dev cyrus-sasl-dev \
                     bison libcap-ng-dev"

ARG QEMU_DISABLE_FEATURES="spice smartcard usb-redir nettle docs xen \
                           debug-info guest-agent-msi gcrypt lzo vte \
                           guest-agent sdl brlapi capstone glusterfs \
                           opengl live-block-migration virglrenderer \
                           vhost-net qom-cast-debug modules libiscsi \
                           crypto-afalg replication libnfs debug-tcg \
                           cocoa snappy numa gnutls mpath linux-user \
                           bsd-user  xen-pci-passthrough user  bzip2 \
                           tpm gtk rdma"

RUN apk add --no-cache ${QEMU_BUILD_PKGS}

SHELL [ "/bin/bash", "-c" ]

RUN adduser -S bob \
    && mkdir -p /build \
    && chown bob /build

USER bob

RUN cd /build \
    && git clone --depth 1 --single-branch \
           -b ${QEMU_RELEASE} \
           git://git.qemu-project.org/qemu.git

#
# Apply our patches to QEMU source:
#
COPY patches/*.patch /build/qemu/

USER bob
RUN cd /build/qemu \
    && git submodule update --init slirp \
    && patch -p1 < qemu-clientid-bootfile-handling.patch \
    && patch -p1 < qemu-envcmdline.patch \
    && patch -p1 < qemu-root-path.patch

RUN cd /build/qemu \
    && set -x \
    && ./configure \
           $(echo "${QEMU_DISABLE_FEATURES}" | \
             sed -e 's#^\|  *# --disable-#g') \
           --target-list=$(uname -m)-softmmu \
           --prefix=/usr \
           --sysconfdir=/etc

RUN cd /build/qemu \
    && make -j$(nproc)

USER root
RUN chown -R root /build/qemu
RUN cd /build/qemu \
    && DESTDIR=/tmp/qemu make install 

# Let's trim up the toupé!
ARG RETAIN_BIOSES="vgabios-stdvga.bin \ 
                   bios-256k.bin      \
                   efi-e1000.rom      \
                   efi-virtio.rom     \
                   kvmvapic.bin"

RUN find /tmp/qemu/usr/share/qemu/ -type f -maxdepth 1 \
    | egrep -v "/($(echo ${RETAIN_BIOSES} | sed 's#  *#|#g'))\$" \
    | xargs -r rm && \
    find /tmp/qemu/usr/share/qemu/keymaps/ -type f \
    | egrep -v '/en-us$' | xargs -r rm

FROM alpine:3.16

ARG QEMU_RUNTIME_PKGS="libaio libgcc libjpeg cyrus-sasl curl openssh \
                       pixman bash glib unfs3 libpng zstd libseccomp \
                       busybox-extras"

RUN apk add --no-cache ${QEMU_RUNTIME_PKGS} 

COPY --from=build-qemu /tmp/qemu/* /usr/
