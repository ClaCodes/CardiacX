package main

import (
	"fmt"
	"math"
)

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

func cardiac(memory *[100]int16, startPc int16, inp inpFn, out outFn) {
	var acc int16 = 0
	var pc = startPc

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
			acc = acc * int16(math.Pow(10, float64(l))) / int16(math.Pow(10, float64(r)))
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

func inpStdin() int16 {
	var input string
	fmt.Scanln(&input)
	var number int16
	fmt.Sscan(input, &number)
	return number
}

func makeInstruction(opcode OpCode, address int16) int16 {
	return int16(opcode)*100 + address
}

func main() {
	var memory [100]int16
	cardiac(&memory, 0, inpStdin, outStdout)
}
