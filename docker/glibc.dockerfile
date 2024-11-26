# docker build -t glibc:2.38-keep-frame-pointers -f glibc.dockerfile .

FROM ubuntu:22.04 as build-env

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
RUN apt-get install -y wget build-essential m4 flex gawk bison python3

ARG GLIBC_VERSION=2.38
RUN wget -q https://ftpmirror.gnu.org/glibc/glibc-${GLIBC_VERSION}.tar.gz -O - | tar -xzf -

ARG CFLAGS=-O1\ -fno-omit-frame-pointer
RUN mkdir /glibc-build && cd /glibc-build && \
    CFLAGS="${CFLAGS}" ../glibc-${GLIBC_VERSION}/configure --prefix=/usr/local/lib/glibc-${GLIBC_VERSION} && \
    make -j$(nproc) && make install

FROM scratch

ARG GLIBC_VERSION=2.38

COPY --from=build-env /usr/local/lib/glibc-${GLIBC_VERSION}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=build-env /usr/local/lib/glibc-${GLIBC_VERSION}/lib/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=build-env /usr/local/lib/glibc-${GLIBC_VERSION}/lib/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=build-env /usr/local/lib/glibc-${GLIBC_VERSION}/lib/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=build-env /usr/local/lib/glibc-${GLIBC_VERSION}/lib/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1
COPY --from=build-env /usr/local/lib/glibc-${GLIBC_VERSION}/lib/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib:/usr/lib/x86_64-linux-gnu
