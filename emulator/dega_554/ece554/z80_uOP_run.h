#ifndef __Z80_UOP_RUN_H
#define __Z80_UOP_RUN_H

void XLATE_CLEAR(void);
void EMIT_PC_DISP(int inst, unsigned int PC_disp);
void EMIT_F_MASK(int inst, unsigned int F_mask);
void EMIT_EOI(int inst);

unsigned int Z80_BYTE(unsigned int byte);
unsigned int REG_CONV8(unsigned int z80_reg);
unsigned int REG_CONV_CELP(unsigned int z80_reg);
unsigned int REG_CONV_CELF(unsigned int z80_reg);
unsigned int REG_CONV_CEXP(unsigned int z80_reg);
unsigned int REG_CONV_CEYP(unsigned int z80_reg);
unsigned int Z80_CC_BPOS(unsigned int z80_cc);

void EMIT_INST_RRR(int inst, unsigned int opcode, unsigned int Rd, unsigned int Rs, unsigned int Rt);
void EMIT_INST_RRI(int inst, unsigned int opcode, unsigned int Rd, unsigned int Rs, int IMM);
void EMIT_INST_RI(int inst, unsigned int opcode, unsigned int Rd, int IMM);
void XLATE_VALID_SET(int a);

void uINSTR_RUN(unsigned char z80_ID);

//#define TRACE

#ifdef TRACE
extern unsigned int inst_count;
#endif


#endif