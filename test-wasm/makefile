
ZIG=zig

test.wasm: test.zig
	zig build-lib test.zig -target wasm32-freestanding -dynamic -rdynamic -O ReleaseSmall

test:
	$(ZIG) test asm.zig

decompile: test.wasm
	wasm2wat test.wasm

clean:
	rm -f test.wasm test.wasm.o
