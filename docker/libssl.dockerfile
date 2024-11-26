# docker build -t libssl:3.2.0-keep-frame-pointers -f libssl.dockerfile .

FROM ubuntu:22.04 as build-env

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
RUN apt-get install -y wget build-essential m4 flex gawk bison python3

ARG OPENSSL_VERSION=3.2.0
ARG CFLAGS=-O2\ -fno-omit-frame-pointer

RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O - | tar -xzf -
RUN cd openssl-${OPENSSL_VERSION} && \
    ./config --prefix=/usr/local/lib/libssl-${OPENSSL_VERSION} && make -j$(nproc) && make install

FROM scratch

ARG OPENSSL_VERSION=3.2.0

COPY --from=build-env /usr/local/lib/libssl-${OPENSSL_VERSION}/lib64/libcrypto.so.3 /lib/x86_64-linux-gnu/libcrypto.so.3
COPY --from=build-env /usr/local/lib/libssl-${OPENSSL_VERSION}/lib64/libssl.so.3 /lib/x86_64-linux-gnu/libssl.so.3

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib:/usr/lib/x86_64-linux-gnu
