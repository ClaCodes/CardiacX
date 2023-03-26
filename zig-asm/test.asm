
// comment
    // comment

// case does not matter? is this a bad idea

anylabel:
another_label:

CLA const_3
ADD const_minus_6
SFT 21 // * 100 / 10
STO     output
OUT oUtPut
STO 00
    hrs  1

const_3: 3
const_minus_6: -6
output: 
111
222

// if comment is uncommented, then should yield an error
mylabel: clA const_3  // cla const3
