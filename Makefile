build:
	RUSTFLAGS=--cfg=web_sys_unstable_apis cargo build --release --target wasm32-unknown-unknown
	wasm-bindgen --no-typescript --out-dir target/generated-gpu --web target/wasm32-unknown-unknown/release/mandelbrot-explorer-rs.wasm

run:
	http-server

run_local:
	WGPU_ADAPTER_NAME="AMD Radeon Pro 5500M" RUSTFLAGS=--cfg=web_sys_unstable_apis cargo run --target x86_64-apple-darwin
