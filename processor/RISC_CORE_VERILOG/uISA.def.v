/////////////////////////////////////////////////////
// uISA.def.v
// micro-ISA definitions
//
// Dec, 2002
// Written by ikim
/////////////////////////////////////////////////////

// register definitions////////////////////////////////////
parameter
rR0 = 5'b00000,
rA  = 5'b01111,
rF  = 5'b01101,
rB  = 5'b00001,
rC  = 5'b00011,
rD  = 5'b00101,
rE  = 5'b00111,
rH  = 5'b01001,
rL  = 5'b01011,
rI  = 5'b00100,
rR  = 5'b01000,
rT0 = 5'b00010,
rT1 = 5'b00110,
rT2 = 5'b01010,
rT3 = 5'b01110,
rSP = 5'b11001,
rAF = 5'b11100,
rBC = 5'b10000,
rDE = 5'b10100,
rHL = 5'b11000,
rIX = 5'b10001,
rIY = 5'b10101,
rT10 = 5'b10010,
rT32 = 5'b11010,
rAFs = 5'b11111,  // shadow
rBCs = 5'b10011,  // shadow
rDEs = 5'b10111,  // shadow
rHLs = 5'b11011;  // shadow

// opcode definitions////////////////////////////////////
parameter
ADD_op  	= 6'H00,
ADDI_op  	= 6'H01,
SUB_op  	= 6'H02,
ADD16_op  	= 6'H03,
ADDI16_op  	= 6'H04,
SUB16_op  	= 6'H05,
AND_op  	= 6'H06,
ANDI_op  	= 6'H07,
OR_op  		= 6'H08,
ORI_op  	= 6'H09,
XOR_op  	= 6'H0A,
XORI_op  	= 6'H0B,
NOT_op  	= 6'H0C,
SHIFTROTATE_op  = 6'H0D,
GET4_op  	= 6'H0E,
MERGE44_op  	= 6'H0F,
MVPC_op  	= 6'H10,
DAA_op  	= 6'H11,
GETBIT_op  	= 6'H12,
NGETBIT_op  	= 6'H13,
SETBIT_op  	= 6'H14,
NSETBIT_op  	= 6'H15,
J_op  		= 6'H20,
JR_op  		= 6'H21,
JC_op  		= 6'H22,
JRC_op  	= 6'H23,
BNE_op  	= 6'H24,
BEQ_op  	= 6'H25,
LD_op  		= 6'H30,
ST_op  		= 6'H31,
LIMM_op  	= 6'H16,
EI_op  		= 6'H17,
DI_op  		= 6'H18,
IM_op  		= 6'H19,
IN_op  		= 6'H32,
OUT_op  	= 6'H33,

SUBI_op     = 6'H1A,
SUBI16_op   = 6'H1B,
MVIFF_op    = 6'H1C,
IFF2IFF1_op = 6'H1D;
