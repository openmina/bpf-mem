# docker build -t openmina:keep-frame-pointers .

FROM glibc:2.38-keep-frame-pointers as glibc

FROM libgcc_s:13.2.0-keep-frame-pointers as libgcc_s

FROM libssl:3.2.0-keep-frame-pointers as libssl

FROM ubuntu:23.10 as build-env

RUN apt-get update && \
    apt-get install -y build-essential curl git libssl-dev libjemalloc-dev jq

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH=${PATH}:/root/.cargo/bin/

RUN rustup update nightly-2023-12-22 && \
    rustup default nightly-2023-12-22 && \
    rustup component add rustfmt

RUN apt-get install -y pkg-config

RUN cargo install --git https://github.com/openmina/openmina --branch develop --bin openmina cli

FROM scratch

COPY --from=glibc /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=glibc /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=glibc /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=glibc /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=glibc /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1
COPY --from=glibc /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0

COPY --from=libgcc_s /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=libgcc_s /lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6

COPY --from=libssl /lib/x86_64-linux-gnu/libcrypto.so.3 /lib/x86_64-linux-gnu/libcrypto.so.3
COPY --from=libssl /lib/x86_64-linux-gnu/libssl.so.3 /lib/x86_64-linux-gnu/libssl.so.3

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu:/usr/lib:/usr/lib/x86_64-linux-gnu

COPY --from=build-env /root/.cargo/bin/openmina /usr/bin/openmina

ENV BPF_MEM="1"

ENTRYPOINT ["/usr/bin/openmina", "node"]
