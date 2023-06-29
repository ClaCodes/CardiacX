CLA eight
JMP plus_14
JMP print
JMP plus_14
JMP print
JMP plus_14
JMP print
HRS

eight: 8

print:
STO tempA
CLA 99
STO print_exit
OUT tempA
CLA tempA
print_exit: 0
tempA: 0

plus_14:
STO tempB
CLA 99
STO plus_14_exit
CLA tempB
ADD forteen
plus_14_exit: 0
tempB: 0
forteen: 14
