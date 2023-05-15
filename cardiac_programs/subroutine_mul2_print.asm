CLA A
STO P // store parameter for subroutine
JMP MUL2
JMP PRINT
CLA B
STO P // store parameter for subroutine
JMP MUL2
JMP PRINT
HRS

// doubles the parameter P
MUL2:
CLA P // load parameter
ADD P // add parameter again (aka doubling)
STO P // store parameter
CLA 99 // load return address
STO MUL2RET
MUL2RET:
0

// outputs the parameter P
PRINT:
OUT P // output parameter
CLA 99 // load return address
STO PRINTRET
PRINTRET:
0

A: 3
B: 5
P: 0 // parameter for subroutines
T: 0 // temporary for subroutines
