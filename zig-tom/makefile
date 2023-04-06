
ZIG=zig

run: cardiac
	./cardiac

cardiac: cardiac.zig
	$(ZIG) build-exe cardiac.zig

format:
	$(ZIG) fmt cardiac.zig

test:
	$(ZIG) test cardiac.zig

clean:
	rm cardiac cardiac.o
