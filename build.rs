// cargo +nightly-2022-10-10 rustc --bin=bpf-mem-kern --features=kern --no-default-features --target=bpfel-unknown-none -Z build-std=core --release -- -Cdebuginfo=2 -Clink-arg=--disable-memory-builtins -Clink-arg=--keep-btf

fn main() {
    #[cfg(feature = "user")]
    build_bpf()
}

#[cfg(feature = "user")]
fn build_bpf() {
    use std::{env, process::Command};

    let output = Command::new("git")
        .args(["rev-parse", "HEAD"])
        .output()
        .unwrap();
    let git_hash = String::from_utf8(output.stdout).unwrap();
    println!("cargo:rustc-env=GIT_HASH={}", git_hash);

    let target_dir = env::var("CARGO_TARGET_DIR").unwrap_or_else(|_| "target".to_string());

    Command::new("sed")
        .current_dir(&target_dir)
        .arg("-i")
        .arg("s/ty__/type/g")
        .arg("bpfel-unknown-none/release/bpf-mem-kern")
        .output()
        .expect("failed to patch bpf object");

    println!("cargo:rustc-env=BPF_MEM={target_dir}/bpfel-unknown-none/release/bpf-mem-kern",);
    println!("cargo:rerun-if-changed=src/main.rs");
}
