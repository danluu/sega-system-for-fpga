/*==========================================================================================*
|	Z80 micro instruction function									|
|																							|
|						Writen by SMS-IO Group (Tsung-Hao, Chen ; Tsung-Chi, Lin)			|
| ----------------------------------------------------------------------------------------- |
|	Date:																					|
|	11/11/2002	Original version established.											|
*==========================================================================================*/

#ifndef __MICRO_INST_H
#define __MICRO_INST_H

class temp_reg
{
public:
	unsigned short T10, T32;

	temp_reg() {  T10 = 0;  T32 = 0;  }
	
};

extern temp_reg t0123;


// unsigned char micro_get_reg8(unsigned char reg);
// void micor_write_reg8(unsigned char reg, unsigned char value);
// unsigned short micro_get_reg16(unsigned char reg);;
// void micor_write_reg16(unsigned char reg, unsigned short value);



bool micro_inst(unsigned int mop_hi, unsigned int mop_lo);




#endif

