package main

import "fmt"

type OpCode int

const (
	INP OpCode = iota
	CLA
	ADD
	TAC
	SFT
	OUT
	STO
	SUB
	JMP
	HRS
)

type inpFn func() int16
type outFn func(int16)

func power(base int16, exponent int16) int16 {
	result := int16(1)
	for i := int16(0); i < exponent; i += 1 {
		result *= base
	}
	return result
}

func cardiac(memory *[100]int16, inp inpFn, out outFn) {
	var acc int16 = 0
	var pc int16 = 1

	memory[0] = 1

	for {
		instruction := memory[pc]
		opcode := OpCode(instruction / 100)
		address := instruction % 100

		pc += 1

		switch opcode {
		case INP:
			memory[address] = inp() % 1000
		case CLA:
			acc = memory[address]
		case ADD:
			acc += memory[address]
		case TAC:
			if acc < 0 {
				pc = address
			}
		case SFT:
			l := address / 10
			r := address % 10
			acc = acc * power(10, l) / power(10, r)
		case OUT:
			out(memory[address])
		case STO:
			memory[address] = acc
		case SUB:
			acc -= memory[address]
		case JMP:
			memory[99] = 800 + pc
			pc = address
		case HRS:
			pc = address
			return
		}
		acc %= 1000
	}
}

func outNull(_ int16) {}

func outStdout(value int16) {
	fmt.Printf("%d\n", value)
}

func inp666() int16 {
	return 666
}

func makeInstruction(opcode OpCode, address int16) int16 {
	return int16(opcode)*100 + address
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

func main() {
	var memory [100]int16
	programDemo(&memory)
	cardiac(&memory, inp666, outStdout)
	fmt.Printf("memory[23] = %d\nmemory[24] = %d\n", memory[23], memory[24])
}
