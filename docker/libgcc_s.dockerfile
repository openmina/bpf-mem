# docker build -t libgcc_s:13.2.0-keep-frame-pointers -f libgcc_s.dockerfile .

FROM ubuntu:23.10 as build-env

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
RUN apt-get install -y wget build-essential m4 flex gawk bison python3

ARG GCC_VERSION=13.2.0
ARG CFLAGS=-O2\ -fno-omit-frame-pointer

RUN wget -q https://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz && \
    tar xf gcc-${GCC_VERSION}.tar.xz && cd gcc-${GCC_VERSION} && contrib/download_prerequisites
RUN mkdir /gcc-build && cd /gcc-build && \
    CFLAGS="${CFLAGS}" ../gcc-${GCC_VERSION}/configure -v --build=x86_64-linux-gnu --host=x86_64-linux-gnu \
        --target=x86_64-linux-gnu --prefix=/usr/local/gcc-${GCC_VERSION} --enable-checking=release \
        --enable-languages=c,c++ --disable-multilib --program-suffix=-10.3 && \
    make -j$(nproc) && make install

FROM scratch

ARG GCC_VERSION=13.2.0

COPY --from=build-env /usr/local/gcc-${GCC_VERSION}/lib64/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=build-env /usr/local/gcc-${GCC_VERSION}/lib64/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib:/usr/lib/x86_64-linux-gnu
