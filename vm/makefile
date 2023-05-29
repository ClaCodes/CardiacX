
ZIG=zig

vm.wasm: vm.zig
	zig build-lib vm.zig -target wasm32-freestanding -dynamic -rdynamic -O ReleaseSmall

clean:
	rm -f vm.wasm vm.wasm.o
