package main

import "testing"

func TestMakeInstruction(t *testing.T) {
	if makeInstruction(CLA, 23) != 123 {
		t.Errorf("Failed")
	}
}

func TestProgramDemo(t *testing.T) {
	var memory [100]int16
	programDemo(&memory)

	if (memory[23] != 999) || (memory[24] != 888) {
		t.Errorf("Failed")
	}

	cardiac(&memory, inp666, outNull)

	if (memory[23] != -90) || (memory[24] != 666) {
		t.Errorf("Failed")
	}
}
