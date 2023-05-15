package main

import "testing"

func TestMakeInstruction(t *testing.T) {
	if makeInstruction(CLA, 23) != 123 {
		t.Errorf("Failed")
	}
}

func programDemo(memory *[100]int16) {
	// code - main
	memory[1] = makeInstruction(CLA, 20)
	memory[2] = makeInstruction(ADD, 21)
	memory[3] = makeInstruction(SFT, 21) // * 100 / 10
	memory[4] = makeInstruction(STO, 23)
	memory[5] = makeInstruction(OUT, 23)
	memory[6] = makeInstruction(JMP, 10) // jump to subroutine
	memory[7] = makeInstruction(HRS, 1)

	// code - subroutine
	memory[10] = makeInstruction(INP, 24)
	memory[11] = makeInstruction(OUT, 24)
	memory[12] = makeInstruction(CLA, 99) // load return address
	memory[13] = makeInstruction(STO, 14) // store return address in next cell
	memory[14] = 0                        // will be filled by previous command

	// data - main
	memory[20] = -3
	memory[21] = -6
	memory[23] = 999

	// data - subroutine
	memory[24] = 888
}

func TestProgramDemo(t *testing.T) {
	var memory [100]int16
	programDemo(&memory)

	if (memory[23] != 999) || (memory[24] != 888) {
		t.Errorf("Failed")
	}

	cardiac(&memory, 1, inp666, outNull)

	if (memory[23] != -90) || (memory[24] != 666) {
		t.Errorf("Failed")
	}
}
