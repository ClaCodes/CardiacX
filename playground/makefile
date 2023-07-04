
ZIG=zig

playground.wasm: playground.zig asm.zig cardiac.zig
	zig build-lib playground.zig -target wasm32-freestanding -dynamic -rdynamic -O ReleaseSmall

clean:
	rm -f playground.wasm playground.wasm.o
