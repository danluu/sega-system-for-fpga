/*==========================================================================================*
|	Z80 Instructions Execution																|
|																							|
|						Writen by			 Tsung-Chi, Lin		(I/O group)					|
| ----------------------------------------------------------------------------------------- |
|	Date:																					|
|	11/01/2002	Original version established.												|
|	11/03/2002	Complete Load Group Instruction												|
|	11/04/2002	Complete Exchange, Block Transfer, Search Group Instruction					|
|	11/04/2002	Complete Arithmetic Group Instruction 										|
|	11/05/2002	Complete ROTATE and SHIFT Group Instruction									|
|	11/05/2002	Complete BIT, RESET, and TEST Group Instruction								|
|	11/05/2002	Complete JUMP Group Instruction												|
|	11/05/2002	Complete CALL and RETURN Group Instruction									|
|	11/06/2002	Complete INPUT and OUTPUT Group Instruction									|
*==========================================================================================*/
#ifndef __Z80_I_RUN_H
#define __Z80_I_RUN_H

unsigned short getRegVal (unsigned char r);	//return the value of specified Register
void setRegVal (unsigned char r, unsigned short v); //store the value to specified Register
unsigned short getRegPairVal_dd (unsigned char dd); //return the value to specified Register
void setRegPairVal_dd (unsigned char dd, unsigned short v); //store the value to specified Register
unsigned short getRegPairVal_qq (unsigned char qq); //return the value to specified Register
void setRegPairVal_qq (unsigned char qq, unsigned short v); //store the value to specified Register
unsigned short getRegPairVal_pp (unsigned char pp); //return the value to specified Register
void setRegPairVal_pp (unsigned char pp, unsigned short v); //store the value to specified Register
unsigned short getRegPairVal_rr (unsigned char rr); //return the value to specified Register
void setRegPairVal_rr (unsigned char rr, unsigned short v); //store the value to specified Register
unsigned short Arith_add8(unsigned short opd1, unsigned short opd2);
unsigned short Arith_sub8(unsigned short opd1, unsigned short opd2);

unsigned short Arith_add16(unsigned short opd1, unsigned short opd2);
unsigned short Arith_sub16(unsigned short opd1, unsigned short opd2);
unsigned short Arith_and(unsigned short opd1, unsigned short opd2);
unsigned short Arith_or(unsigned short opd1, unsigned short opd2);
unsigned short Arith_xor(unsigned short opd1, unsigned short opd2);
void parity_check(unsigned short opd);
void sign_check(unsigned short opd);
void zero_check(unsigned short opd);
void getSpecBit(unsigned short opd, unsigned short bit_num);		// use for BIT Group
unsigned short setSpecBit(unsigned short opd, unsigned short bit_num);	// use for SET Group
unsigned short resSpecBit(unsigned short opd, unsigned short bit_num);	// use for SET Group
void overflow_check8(unsigned short opd1, unsigned short opd2);
void overflow_check16(unsigned short opd1, unsigned short opd2);
bool condition_check(unsigned char cond);

int sign_extend(unsigned char a);
int sign_extend(unsigned short a);

void INSTR_RUN(unsigned char z80_ID);


#endif