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

RUN RUSTFLAGS="-Cforce-frame-pointers=yes" cargo install --git https://github.com/openmina/openmina --branch develop --bin openmina cli

RUN apt-get install -y libelf-dev

RUN cargo install bpf-linker --git https://github.com/vlad9486/bpf-linker.git --branch keep-btf

RUN rustup install nightly-2022-10-10 && \
    rustup component add rust-src --toolchain nightly-2022-10-10-x86_64-unknown-linux-gnu

RUN git clone https://github.com/openmina/bpf-mem.git
WORKDIR /bpf-mem
RUN cargo +nightly-2022-10-10 rustc --bin=bpf-mem-kern --features=kern --no-default-features \
    --target=bpfel-unknown-none -Z build-std=core --release -- \
    -Cdebuginfo=2 -Clink-arg=--disable-memory-builtins -Clink-arg=--keep-btf && \
    sed -i 's/ty__/type/g' target/bpfel-unknown-none/release/bpf-mem-kern
RUN cargo install --path . --bin bpf-mem-user bpf-mem

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

COPY --from=build-env /bin/sh /bin/sh
COPY --from=build-env /usr/bin/sleep /usr/bin/sleep
COPY --from=build-env /root/.cargo/bin/bpf-mem-user /usr/bin/bpf-mem-user
COPY --from=build-env /root/.cargo/bin/openmina /usr/bin/openmina
COPY --from=build-env /lib/x86_64-linux-gnu/libelf.so.1 /lib/x86_64-linux-gnu/libelf.so.1
COPY --from=build-env /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=build-env /lib/x86_64-linux-gnu/libzstd.so.1 /lib/x86_64-linux-gnu/libzstd.so.1

ENTRYPOINT ["/bin/sh", "-c", "RUST_LOG=info /usr/bin/bpf-mem-user & /usr/bin/sleep 1 && BPF_MEM=1 /usr/bin/openmina node"]
