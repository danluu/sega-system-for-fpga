///////////////////////////////////////////////////////////
// micro-ISA definitions
///////////////////////////////////////////////////////////
#ifndef __MICRO_ISA_ID_H
#define __MICRO_ISA_ID_H

//internal variables
#define xlate0 0
#define xlate1 1
#define xlate2 2
#define xlate3 3
#define xlate4 4
#define xlate5 5
#define xlate6 6
#define xlate7 7
#define xlate8 8
#define xlate9 9
// register definitions////////////////////////////////////

#define rR0 0x00 //  = 5'b00000,
#define rA  0x0f //  = 5'b01111,
#define rF  0x0d //  = 5'b01101,
#define rB  0x01 //  = 5'b00001,
#define rC  0x03 //  = 5'b00011,
#define rD  0x05 //  = 5'b00101,
#define rE  0x07 //  = 5'b00111,
#define rH  0x09 //  = 5'b01001,
#define rL  0x0b //  = 5'b01011,
#define rI  0x04 //  = 5'b00100,
#define rR  0x08 //  = 5'b01000,
#define rT0 0x02 //  = 5'b00010,
#define rT1 0x06 //  = 5'b00110,
#define rT2 0x0a //  = 5'b01010,
#define rT3 0x0e //  = 5'b01110,
#define rSP 0x19 //  = 5'b11001,
#define rAF 0x1c //  = 5'b11100,
#define rBC 0x10 //  = 5'b10000,
#define rDE 0x14 //  = 5'b10100,
#define rHL 0x18 //  = 5'b11000,
#define rIX 0x11 //  = 5'b10001,
#define rIY 0x15 //  = 5'b10101,
#define rT10 0x12 //  = 5'b10010,
#define rT32 0x1a //  = 5'b11010,
#define rAFs 0x1f //  = 5'b11111,  // shadow
#define rBCs 0x13 //  = 5'b10011,  // shadow
#define rDEs 0x17 //  = 5'b10111,  // shadow
#define rHLs 0x1b //  = 5'b11011;  // shadow
// opcode definitions////////////////////////////////////
#define ADD_op  	0x00
#define ADDI_op  	0x01
#define SUB_op  	0x02
#define ADD16_op  	0x03
#define ADDI16_op  	0x04
#define SUB16_op  	0x05
#define AND_op  	0x06
#define ANDI_op  	0x07
#define OR_op  		0x08
#define ORI_op  	0x09
#define XOR_op  	0x0A
#define XORI_op  	0x0B
#define NOT_op  	0x0C
#define SHIFTROTATE_op  0x0D
#define GET4_op  	0x0E
#define MERGE44_op  0x0F
#define MVPC_op  	0x10
#define DAA_op  	0x11
#define GETBIT_op  	0x12
#define NGETBIT_op  0x13
#define SETBIT_op  	0x14
#define NSETBIT_op  0x15
#define J_op  		0x20
#define JR_op  		0x21
#define JC_op  		0x22
#define JRC_op  	0x23
#define BNE_op  	0x24
#define BEQ_op  	0x25
#define LD_op  		0x30
#define ST_op  		0x31
#define LIMM_op  	0x16
#define EI_op  		0x17
#define DI_op  		0x18
#define IM_op  		0x19
#define IN_op  		0x32
#define OUT_op  	0x33

#define SUBI_op     0x1A
#define SUBI16_op   0x1B
#define MVIFF_op    0x1C
#define IFF2IFF1_op 0x1D

#endif