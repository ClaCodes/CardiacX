CLA A // acc = [A] = 3
TAC halt // acc >= 0, should not branch
STO C // [C] = acc = 3
OUT C
CLA ZERO
TAC halt // acc >= 0, should not branch
STO C // [C] = acc = 3
OUT C
CLA B // acc = [B] = -5
TAC halt // acc < 0, should branch
STO C // [C] = acc = -5
OUT C

halt:
HRS

A: 3
ZERO: 0
B: -5
C: 0
