
// comment
    // comment


anylabel:
another_label:

CLA const_3
ADD const_minus_6
SFT 21 // * 100 / 10
STO     output
OUT output
STO 00
    HRS  1

const_3: 3
const_minus_6: -6
output: 
111
222

// if following comment is uncommented, an error should happen
mylabel: CLA const_3  // CLA const3
