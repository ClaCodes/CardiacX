
# CardiacX

Cardiac is a 1989 learning aid to teach how Computers work. It was developed by David Hagelbarger.

https://www.cs.drexel.edu/~bls96/museum/cardiac.html
https://www.cs.drexel.edu/~bls96/museum/cardsim.html
https://en.wikipedia.org/wiki/CARDboard_Illustrative_Aid_to_Computation

The primary purpose of this repo was to primarily play with Zig. At the moment this repository contains:

- 2 emulators written by different people in Zig
- 1 emulator written in Go
- An assembler written in Zig
- The assembler and emulator working inside the WebBrowser via WebAssembly
- A test suite using Zig
- A build system using Zig
- Quite a few examples, including the expected output, which then is used by the test suite

The easiest way to contribute is:

- Use the Cardiac Sim webpage to learn about the Cardiac and write another example
- Write another emulator in whatever language you like
