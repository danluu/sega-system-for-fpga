/*==========================================================================================*
|	Z80 Instructions Execution																|
|																							|
|						Writen by					Tsung-Chi, Lin		(I/O group)			|
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
|	11/10/2002	Fix the document error of Instruction 'ADD_IX_pp'							| 
|	11/12/2002	Fix the Problem with not updating Flag Instruction							|
|	11/14/2002	Fix the P/V and Z flag in BC-- Instruction									|
|	11/15/2002	Fix the repeated Block Instruction											|
|	11/19/2002	Fix the Jump Instruction													|
|	11/22/2002	Fix the LD_nn_dd (nn2->nn1)													|
|	11/24/2002	Fix the ADC, SBC flag problem												|
|	11/24/2002	Fix the CPI, CPIR, CPD, CPDR Instruction									|
*==========================================================================================*/

#include "..\\mast\\doze.h"
#include "dozeint_554.h"
#include "DataValue.h"
#include "z80_I_ID.h"
#include "z80_I_run.h"


unsigned short getRegVal (unsigned char r)	//return the value of specified Register
{
	switch (r)
	{
		case 0x07:	// Reg A
			return (unsigned short)(Doze.af >> 8);
			break;
		case 0x00:	// Reg B
			return (unsigned short)(Doze.bc >> 8);
			break;
		case 0x01:	// Reg C
			return (unsigned short)(Doze.bc & 0x00ff);
			break;
		case 0x02:	// Reg D
			return (unsigned short)(Doze.de >> 8);
			break;
		case 0x03:	// Reg E
			return (unsigned short)(Doze.de & 0x00ff);
			break;
		case 0x04:	// Reg H
			return (unsigned short)(Doze.hl >> 8);
			break;
		case 0x05:	// Reg L
			return (unsigned short)(Doze.hl & 0x00ff);
			break;
		default: return 0x0000;
	}
}

void setRegVal (unsigned char r, unsigned short v) //store the value to specified Register
{
	switch (r)
	{
		case 0x07:	// Reg A
			Doze.af = (unsigned short)((v<<8) + (Doze.af & 0x00ff));
			break;
		case 0x00:	// Reg B
			Doze.bc = (unsigned short)((v<<8) + (Doze.bc & 0x00ff));
			break;
		case 0x01:	// Reg C
			Doze.bc = (unsigned short)(v + (Doze.bc & 0xff00));
			break;
		case 0x02:	// Reg D
			Doze.de = (unsigned short)((v<<8) + (Doze.de & 0x00ff));
			break;
		case 0x03:	// Reg E
			Doze.de = (unsigned short)(v + (Doze.de & 0xff00));
			break;
		case 0x04:	// Reg H
			Doze.hl = (unsigned short)((v<<8) + (Doze.hl & 0x00ff));
			break;
		case 0x05:	// Reg L
			Doze.hl = (unsigned short)(v + (Doze.hl & 0xff00));
			break;
		case 0x06:	//Not specified
			break;
	}
}

unsigned short getRegPairVal_dd (unsigned char dd) //return the value to specified Register
{
	switch (dd)
	{
		case 0x00:	// RegPair BC
			return Doze.bc;
			break;
		case 0x01:	// RegPair DE
			return Doze.de;
			break;
		case 0x02:	// RegPair HL
			return Doze.hl;
			break;
		case 0x03:	// RegPair SP
			return Doze.sp;
			break;
		default: return 0x0000;
	}
}

void setRegPairVal_dd (unsigned char dd, unsigned short v) //store the value to specified Register
{
	switch (dd)
	{
		case 0x00:	// RegPair BC
			Doze.bc = v;
			break;
		case 0x01:	// RegPair DE
			Doze.de = v;
			break;
		case 0x02:	// RegPair HL
			Doze.hl = v;
			break;
		case 0x03:	// RegPair SP
			Doze.sp = v;
			break;
	}
}

unsigned short getRegPairVal_qq (unsigned char qq) //return the value to specified Register
{
	switch (qq)
	{
		case 0x00:	// RegPair BC
			return Doze.bc;
			break;
		case 0x01:	// RegPair DE
			return Doze.de;
			break;
		case 0x02:	// RegPair HL
			return Doze.hl;
			break;
		case 0x03:	// RegPair AF
			return Doze.af;
			break;
		default: return 0x0000;
	}
}

void setRegPairVal_qq (unsigned char qq, unsigned short v) //store the value to specified Register
{
	switch (qq)
	{
		case 0x00:	// RegPair BC
			Doze.bc = v;
			break;
		case 0x01:	// RegPair DE
			Doze.de = v;
			break;
		case 0x02:	// RegPair HL
			Doze.hl = v;
			break;
		case 0x03:	// RegPair AF
			Doze.af = v;
			break;
	}
}

unsigned short getRegPairVal_pp (unsigned char pp) //return the value to specified Register
{
	switch (pp)
	{
		case 0x00:	// RegPair BC
			return Doze.bc;
			break;
		case 0x01:	// RegPair DE
			return Doze.de;
			break;
		case 0x02:	// RegPair IX
			return Doze.ix;
			break;
		case 0x03:	// RegPair SP
			return Doze.sp;
			break;
		default: return 0x0000;
	}
}

void setRegPairVal_pp (unsigned char pp, unsigned short v) //store the value to specified Register
{
	switch (pp)
	{
		case 0x00:	// RegPair BC
			Doze.bc = v;
			break;
		case 0x01:	// RegPair DE
			Doze.de = v;
			break;
		case 0x02:	// RegPair IX
			Doze.ix = v;
			break;
		case 0x03:	// RegPair SP
			Doze.sp = v;
			break;
	}
}

unsigned short getRegPairVal_rr (unsigned char rr) //return the value to specified Register
{
	switch (rr)
	{
		case 0x00:	// RegPair BC
			return Doze.bc;
			break;
		case 0x01:	// RegPair DE
			return Doze.de;
			break;
		case 0x02:	// RegPair IY
			return Doze.iy;
			break;
		case 0x03:	// RegPair SP
			return Doze.sp;
			break;
		default: return 0x0000;
	}
}

void setRegPairVal_rr (unsigned char rr, unsigned short v) //store the value to specified Register
{
	switch (rr)
	{
		case 0x00:	// RegPair BC
			Doze.bc = v;
			break;
		case 0x01:	// RegPair DE
			Doze.de = v;
			break;
		case 0x02:	// RegPair IY
			Doze.iy = v;
			break;
		case 0x03:	// RegPair SP
			Doze.sp = v;
			break;
	}
}

unsigned short Arith_add8(unsigned short opd1, unsigned short opd2)
{
	unsigned short temp = (unsigned short)((opd1&0xff) + (opd2&0xff));
	flag.S = ((temp & 0x0080) == 0x0080)? 1:0;
	flag.Z = ((temp & 0x00ff) == 0x0000)? 1:0;
	if ((((opd1 & 0x000f) + (opd2 & 0x000f)) & 0x0010) == 0x0010)	// determine H flag
		flag.H = 1;
	else 
		flag.H = 0;
	if ((_ID != INC_r) && (_ID != INC_HL) && (_ID != INC_IX_d) && (_ID != INC_IY_d))
	{
		if ((((opd1&0xff) + (opd2&0xff)) & 0x0100) == 0x0100)	// determine C flag
			flag.C = 1;
		else 
			flag.C = 0;
	}
	flag.N = 0;
	overflow_check8(opd1, opd2);
	return (unsigned short)(temp&0x00ff);
}

unsigned short Arith_sub8(unsigned short opd1, unsigned short opd2)
{
//	unsigned short opd2_c;
//	opd2c = (opd2 ^ 0x00ff) + 1;		// find the 2's complement
//	unsigned short temp = (opd1 + opd2_c);
	unsigned short temp = (unsigned short)((opd1&0xff) - (opd2&0xff));
	flag.S = ((temp & 0x0080) == 0x0080)? 1:0;
	flag.Z = ((temp & 0x00ff) == 0x0000)? 1:0;
	if ((unsigned short)(opd1 & 0x000f) >= (unsigned short)(opd2 & 0x000f))	// determine H flag
		flag.H = 0;
	else 
		flag.H = 1;
	if ((_ID != DEC_m_1) && (_ID != DEC_m_2) && (_ID != DEC_m_3) && (_ID != DEC_m_4))
	{
		if ((unsigned short)opd1 >= (unsigned short)opd2)	// determine C flag
			flag.C = 0;
		else 
			flag.C = 1;
	}
	flag.N = 1;
	overflow_check8(opd1, opd2);
	return (unsigned short)(temp&0x00ff);
}

unsigned short Arith_add16(unsigned short opd1, unsigned short opd2)
{
	unsigned int temp = (unsigned int)(opd1 + opd2);
	if ((((opd1 & 0x0fff) + (opd2 & 0x0fff)) & 0x1000) == 0x1000)	// determine H flag
		flag.H = 1;
	else 
		flag.H = 0;
	if (((unsigned int)(opd1 + opd2) & 0x10000) == 0x10000)	// determine C flag
		flag.C = 1;
	else 
		flag.C = 0;
	flag.N = 0;
// No S, Z, V update in this function	
	return (unsigned short)(temp&0xffff);
}

unsigned short Arith_sub16(unsigned short opd1, unsigned short opd2)
{
//	unsigned short opd2_c;
//	opd2_c = (opd2 ^ 0xffff) + 1;		// find the 2's complement
//	unsigned int temp = (unsigned int)(opd1 + opd2_c);
	unsigned int temp = (unsigned int)(opd1 - opd2);
	if ((unsigned short)(opd1 & 0x0fff) >= (unsigned short)(opd2 & 0x0fff)) 	// determine H flag
		flag.H = 0;
	else 
		flag.H = 1;
	if ((opd1 >= opd2))	// determine C flag
		flag.C = 0;
	else 
		flag.C = 1;
	flag.N = 1;
// No S, Z, V update in this function
	return (unsigned short)(temp&0xffff);
}

unsigned short Arith_and(unsigned short opd1, unsigned short opd2)
{
	unsigned short temp = (unsigned short)(opd1 & opd2);
	flag.S = ((temp & 0x0080) == 0x0080)? 1:0;
	flag.Z = ((temp & 0x00ff) == 0x0000)? 1:0;
	flag.H = 1;
	flag.C = 0;
	flag.N = 0;
	parity_check(temp);
	return (unsigned short)(temp&0x00ff);
}

unsigned short Arith_or(unsigned short opd1, unsigned short opd2)
{
	unsigned short temp = (unsigned short)(opd1 | opd2);
	flag.S = ((temp & 0x0080) == 0x0080)? 1:0;
	flag.Z = ((temp & 0x00ff) == 0x0000)? 1:0;
	flag.H = 0;
	flag.C = 0;
	flag.N = 0;
	parity_check(temp);
	return (unsigned short)(temp&0x00ff);
}

unsigned short Arith_xor(unsigned short opd1, unsigned short opd2)
{
	unsigned short temp = (unsigned short)(opd1 ^ opd2);
	flag.S = ((temp & 0x0080) == 0x0080)? 1:0;
	flag.Z = ((temp & 0x00ff) == 0x0000)? 1:0;
	flag.H = 0;
	flag.C = 0;
	flag.N = 0;
	parity_check(temp);
	return (unsigned short)(temp&0x00ff);
}

void parity_check(unsigned short opd)
{
	if ((((opd & 0x0080) >> 7)^
	((opd & 0x0040) >> 6)^
	((opd & 0x0020) >> 5)^
	((opd & 0x0010) >> 4)^
	((opd & 0x0008) >> 3)^
	((opd & 0x0004) >> 2)^
	((opd & 0x0002) >> 1)^
	(opd & 0x0001))==0x0000) 
		flag.PV = 1;
	else
		flag.PV = 0;
}

void sign_check(unsigned short opd)
{
	if ((opd & 0x0080) == 0x0080)
		flag.S = 1;
	else 
		flag.S = 0;
}

void zero_check(unsigned short opd)
{
	if ((opd & 0x00ff) == 0x0000)
		flag.Z = 1;
	else flag.Z = 0;
}

void getSpecBit(unsigned short opd, unsigned short bit_num)	// use for BIT Group
{
	switch(bit_num)
	{
	case 0:
		if ((opd & 0x0001) == 0x0000) flag.Z = 1;
		else flag.Z = 0;
		break;
	case 1:
		if ((opd & 0x0002) == 0x0000) flag.Z = 1;
		else flag.Z = 0;
		break;
	case 2:
		if ((opd & 0x0004) == 0x0000) flag.Z = 1;
		else flag.Z = 0;
		break;
	case 3:
		if ((opd & 0x0008) == 0x0000) flag.Z = 1;
		else
		{
			flag.Z = 0;
			flag.no_use1 = 1;	//
		}
		break;
	case 4:
		if ((opd & 0x0010) == 0x0000) flag.Z = 1;
		else flag.Z = 0;
		break;
	case 5:
		if ((opd & 0x0020) == 0x0000) flag.Z = 1;
		else
		{
			flag.Z = 0;
			flag.no_use2 = 1;	//
		}
		break;
	case 6:
		if ((opd & 0x0040) == 0x0000) flag.Z = 1;
		else flag.Z = 0;
		break;
	case 7:
		if ((opd & 0x0080) == 0x0000) flag.Z = 1;
		else 
		{
			flag.Z = 0;
			flag.S = 1;	//
		}
		break;
	default: break;
	}
	flag.PV = flag.Z ? 1 : 0;	//
}

unsigned short setSpecBit(unsigned short opd, unsigned short bit_num)	// use for SET Group
{
	switch(bit_num)
	{
	case 0:
		return (unsigned short)((opd | 0x0001) & 0x00ff);
	case 1:
		return (unsigned short)((opd | 0x0002) & 0x00ff);
	case 2:
		return (unsigned short)((opd | 0x0004) & 0x00ff);
	case 3:
		return (unsigned short)((opd | 0x0008) & 0x00ff);
	case 4:
		return (unsigned short)((opd | 0x0010) & 0x00ff);
	case 5:
		return (unsigned short)((opd | 0x0020) & 0x00ff);
	case 6:
		return (unsigned short)((opd | 0x0040) & 0x00ff);
	case 7:
		return (unsigned short)((opd | 0x0080) & 0x00ff);
	default: return NULL;
	}
}

unsigned short resSpecBit(unsigned short opd, unsigned short bit_num)	// use for SET Group
{
	switch(bit_num)
	{
	case 0:
		return (unsigned short)((opd & 0x00fe) & 0x00ff);
	case 1:
		return (unsigned short)((opd & 0x00fd) & 0x00ff);
	case 2:
		return (unsigned short)((opd & 0x00fb) & 0x00ff);
	case 3:
		return (unsigned short)((opd & 0x00f7) & 0x00ff);
	case 4:
		return (unsigned short)((opd & 0x00ef) & 0x00ff);
	case 5:
		return (unsigned short)((opd & 0x00df) & 0x00ff);
	case 6:
		return (unsigned short)((opd & 0x00bf) & 0x00ff);
	case 7:
		return (unsigned short)((opd & 0x007f) & 0x00ff);
	default: return NULL;
	}
}

int sign_extend(unsigned char a)
{
	return (( a >> 7 ) ? ( 0xffffff00 + a ) : a);
}

int sign_extend(unsigned short a)
{
	return (( a >> 15 ) ? ( 0xffff0000 + a ) : a);
}

void overflow_check8(unsigned short opd1, unsigned short opd2)
{
	int int1, int2;
	if (flag.N)	// subtract operation
	{
		if ((opd1>>7) != (opd2>>7))
		{
			int1 = sign_extend((unsigned char)opd1);
			int2 = sign_extend((unsigned char)opd2);
			if (((int1-int2)> 127) || ((int1-int2)< -128))
				flag.PV = 1;
			else flag.PV = 0;
		}
		else flag.PV = 0;	
	}
	else // addition operation
	{
		if ((opd1>>7) == (opd2>>7))
		{
			int1 = sign_extend((unsigned char)opd1);
			int2 = sign_extend((unsigned char)opd2);
			if (((int1+int2)> 127) || ((int1+int2)< -128))
				flag.PV = 1;
			else flag.PV = 0;
		}
		else flag.PV = 0;			
	}
}

void overflow_check16(unsigned short opd1, unsigned short opd2)
{
	int int1, int2;
	if (flag.N)	// subtract operation
	{
		if ((opd1>>15) != (opd2>>15))
		{
			int1 = sign_extend((unsigned short)opd1);
			int2 = sign_extend((unsigned short)opd2);
			if (((int1-int2)> 127) || ((int1-int2)< -128))
				flag.PV = 1;
			else flag.PV = 0;
		}
		else flag.PV = 0;	
	}
	else // addition operation
	{
		if ((opd1>>15) == (opd2>>15))
		{
			int1 = sign_extend((unsigned short)opd1);
			int2 = sign_extend((unsigned short)opd2);
			if (((int1+int2)> 32767) || ((int1+int2)< -32768))
				flag.PV = 1;
			else flag.PV = 0;
		}
		else flag.PV = 0;			
	}
}

bool condition_check(unsigned char cond)
{
  switch (cond)
  {
	  case 0x00:
		if (!flag.Z) return true;
		else return false;
		break;
	  case 0x01:
		if (flag.Z) return true;
		else return false;
		break;
	  case 0x02:
		if (!flag.C) return true;
		else return false;
		break;
	  case 0x03:
		if (flag.C) return true;
		else return false;
		break;
	  case 0x04:
		if (!flag.PV) return true;
		else return false;
		break;
	  case 0x05:
		if (flag.PV) return true;
		else return false;
		break;
	  case 0x06:
		if (!flag.S) return true;
		else return false;
		break;
	  case 0x07:
		if (flag.S) return true;
		else return false;
		break;
	  default: return false;
  }
}

void INSTR_RUN(unsigned char z80_ID)
{
  unsigned short tempreg;
  unsigned char tempreg2;
  _ID = z80_ID;

	flag.C = (Doze.af & 0x01);			// Carry flag
	flag.N = (Doze.af & 0x02) >> 1;		// Add/Subtract flag
	flag.PV = (Doze.af & 0x04) >> 2;
	flag.no_use1 = (Doze.af & 0x08) >> 3;
	flag.H = (Doze.af & 0x10) >> 4;			// Half_carry flag
	flag.no_use2 = 	(Doze.af & 0x20) >> 5;
	flag.Z = (Doze.af & 0x40) >> 6;			// Zero flag
	flag.S = (Doze.af & 0x80) >> 7;			// Sign flag
	flag.no_use1 = 0;
	flag.no_use2 = 0;

  switch(z80_ID)
  {
	case  NOP:
		nDozeCycles-= 4;
		break;
	case  ADC_A_s_1:
		tempreg = Arith_add8(getRegVal(bus_pre.r2) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 4;
		break;
	case  ADC_A_s_2:
		tempreg = Arith_add8((unsigned short)bus_pre.n2 ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 7; // 8;
		break;
	case  ADC_A_s_3:
		tempreg = Arith_add8((unsigned short)DozeRead(Doze.hl) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 7;
		break;
	case  ADC_A_s_4:
		tempreg = Arith_add8((unsigned short)DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))
			,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 19; //15;
		break;
	case  ADC_A_s_5:
		tempreg = Arith_add8((unsigned short)DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))
			,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 19; //15;
		break;
	case  ADC_HL_ss:
		overflow_check16(getRegPairVal_dd(bus_pre.dd2) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use2 = flag.PV;
		tempreg = Arith_add16(getRegPairVal_dd(bus_pre.dd2) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		overflow_check16(Doze.hl, tempreg);
		flag.PV = flag.PV ^ flag.no_use2;
		Doze.hl = Arith_add16(Doze.hl, tempreg);
		flag.C = flag.C ^ flag.no_use1;
		flag.S = ((Doze.hl & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.hl & 0xffff) == 0)? 1:0;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 15; // 11;
		break;
	case  ADD_A_HL:
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), DozeRead(Doze.hl)) << 8) 
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 7;
		break;
	case  ADD_A_IX_d:
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))) << 8)
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 16; //15;
		break;		
	case  ADD_A_IY_d:
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))) << 8)
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 16; //15;
		break;
	case  ADD_A_n:
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), bus_pre.n2) << 8) 
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 7; // 8
		break;
	case  ADD_A_r:
		Doze.af = (unsigned short)( (Arith_add8((unsigned short)(Doze.af>>8), getRegVal(bus_pre.r2)) << 8) 
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 4;
		break;
	case  ADD_HL_ss:
		Doze.hl = Arith_add16(Doze.hl, getRegPairVal_dd(bus_pre.dd1) );
		nDozeCycles-= 11;
		break;		
	case  ADD_IX_pp:
		Doze.ix = Arith_add16(Doze.ix, getRegPairVal_pp(bus_pre.pp2) );
		nDozeCycles-= 15; // 11;
		break;
	case  ADD_IY_rr:
		Doze.iy = Arith_add16(Doze.iy, getRegPairVal_rr(bus_pre.rr2) );
		nDozeCycles-= 15; // 11;
		break;
	case  AND_s_1:
		Doze.af = (unsigned short)( ((Arith_and((unsigned short)(Doze.af>>8), getRegVal(bus_pre.r2)) << 8)
			+ (Doze.af & 0x00ff)) );
		nDozeCycles-= 4;
		break;		
	case  AND_s_2:
		Doze.af = (unsigned short)( ((Arith_and((unsigned short)(Doze.af>>8), bus_pre.n2) << 8) 
			+ (Doze.af & 0x00ff)) );
		nDozeCycles-= 7; // 8;
		break;
	case  AND_s_3:
		Doze.af = (unsigned short)( ((Arith_and((unsigned short)(Doze.af>>8), DozeRead(Doze.hl)) << 8)
			+ (Doze.af & 0x00ff)) );
		nDozeCycles-= 7;
		break;
	case  AND_s_4:
		Doze.af = (unsigned short)( ((Arith_and((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))) << 8)
			+ (Doze.af & 0x00ff)) );
		nDozeCycles-= 19; // 15;
		break;
	case  AND_s_5:
		Doze.af = (unsigned short)( ((Arith_and((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))) << 8)
			+ (Doze.af & 0x00ff)) );
		nDozeCycles-= 19; // 15;
		break;
	case  BIT_b_HL:
		getSpecBit(DozeRead(Doze.hl),bus_pre.r3);
		flag.H = 1;
		flag.N = 0;
		nDozeCycles-= 12; //8;
		break;
	case  BIT_b_IX_d:
		getSpecBit(DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))), bus_pre.b4);
		flag.H = 1;
		flag.N = 0;
		nDozeCycles-= 20; //16;
		break;
	case  BIT_b_IY_d:
		getSpecBit(DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))), bus_pre.b4);
		flag.H = 1;
		flag.N = 0;
		nDozeCycles-= 20; //16;
		break;
	case  BIT_b_r:
		getSpecBit(getRegVal(bus_pre.r4), bus_pre.r3);
		flag.H = 1;
		flag.N = 0;
		nDozeCycles-= 8; //4;
		break;
	case  CALL_cc_nn:
		if (condition_check(bus_pre.r1))
		{
			Doze.sp--;
			DozeWrite((Doze.sp),(unsigned char)(Doze.pc >> 8));
			Doze.sp--;
			DozeWrite((Doze.sp),(unsigned char)(Doze.pc & 0x00ff));
			Doze.pc = bus_pre.nn1;
			nDozeCycles-= 17;
		}
		else
			nDozeCycles-= 10;
		break;
	case  CALL_nn:
		Doze.sp--;
		DozeWrite((Doze.sp),(unsigned char)(Doze.pc >> 8));
		Doze.sp--;
		DozeWrite((Doze.sp),(unsigned char)(Doze.pc & 0x00ff));
		Doze.pc = bus_pre.nn1;
		nDozeCycles-= 17;
		break;
	case  CCF:
		flag.C = ~flag.C;
		flag.N = 0;
		nDozeCycles-= 4;
		break;
	case  CP_s_1:
		tempreg = Arith_sub8((unsigned short)(Doze.af>>8), getRegVal(bus_pre.r2));
		nDozeCycles-= 4;
		break;
	case  CP_s_2:
		tempreg = Arith_sub8((unsigned short)(Doze.af>>8), bus_pre.n2);
		nDozeCycles-= 7; // 8;
		break;
	case  CP_s_3:
		tempreg = Arith_sub8((unsigned short)(Doze.af>>8), DozeRead(Doze.hl));
		nDozeCycles-= 7;
		break;
	case  CP_s_4:
		tempreg = Arith_sub8((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))));
		nDozeCycles-= 19; //15;
		break;
	case  CP_s_5:
		tempreg = Arith_sub8((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))));
		nDozeCycles-= 19; //15;
		break;
	case  CPD:
		tempreg = (unsigned short)DozeRead(Doze.hl);
		Doze.hl--;
		Doze.bc--;
		tempreg2 = DozeRead(Doze.hl);
		flag.Z = ((Doze.af >> 8) == tempreg2)? 1:0;		//A == (HL)
		flag.S = ((((Doze.af>>8)-tempreg)&0x0080)==0x0080)? 1:0;
		if ((signed short)((Doze.af >> 8) & 0x000f) < (signed short)(tempreg & 0x000f))
			flag.H = 1;
		else
			flag.H = 0;
		flag.N = 1;
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		nDozeCycles-= 16; //12;
		break;		
	case  CPDR:
		tempreg = (unsigned short)DozeRead(Doze.hl);
		Doze.hl--;
		Doze.bc--;
		tempreg2 = DozeRead(Doze.hl);
		if (((Doze.af >> 8) != (unsigned short)tempreg2) && (Doze.bc != 0x0000))
		{
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; //17;
		}
		else
			nDozeCycles-= 16; //12;
		flag.Z = ((Doze.af >> 8) == tempreg2)? 1:0;		//A == (HL)
		flag.S = ((((Doze.af>>8)-tempreg)&0x0080)==0x0080)? 1:0;
		if ((signed short)((Doze.af >> 8) & 0x000f) < (signed short)(tempreg & 0x000f))
			flag.H = 1;
		else
			flag.H = 0;
		flag.N = 1;
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		break;
	case  CPI:
		tempreg = (unsigned short)DozeRead(Doze.hl);
		Doze.hl++;
		Doze.bc--;
		tempreg2 = DozeRead(Doze.hl);
		flag.Z = ((Doze.af >> 8) == tempreg2)? 1:0;		//A == (HL)
		flag.S = ((((Doze.af>>8)-tempreg)&0x0080)==0x0080)? 1:0;
		if ((signed short)((Doze.af >> 8) & 0x000f) < (signed short)(tempreg & 0x000f))
			flag.H = 1;
		else
			flag.H = 0;
		flag.N = 1;
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		nDozeCycles-= 16; //12;
		break;
	case  CPIR:
		tempreg = (unsigned short)DozeRead(Doze.hl);
		Doze.hl++;
		Doze.bc--;
		tempreg2 = DozeRead(Doze.hl);
		if (((Doze.af >> 8) != (unsigned short)tempreg2) && (Doze.bc != 0x0000))
		{
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-=21; //17;
		}
		else
			nDozeCycles-= 16; //12;
		flag.Z = ((Doze.af >> 8) == tempreg2)? 1:0;		//A == (HL)
		flag.S = ((((Doze.af>>8)-tempreg)&0x0080)==0x0080)? 1:0;
		if ((signed short)((Doze.af >> 8) & 0x000f) < (signed short)(tempreg & 0x000f))
			flag.H = 1;
		else
			flag.H = 0;
		flag.N = 1;
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		break;
	case  CPL:
		Doze.af = (unsigned short)(Doze.af ^ 0xff00);
		flag.H = 1;
		flag.N = 1;
		nDozeCycles-= 4;
		break;
	case  DAA:
// flag not complete
		if (!flag.N)
		{
			if (!flag.C && !flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0008)
			&& (((Doze.af >> 8) & 0x000f) >= 0x000A))
			{
				Doze.af = (unsigned short)(Doze.af + 0x0600);
				flag.H = 1;
			}
			else if (!flag.C && flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0009)
			&& (((Doze.af >> 8) & 0x000f) <= 0x0003))
				Doze.af = (unsigned short)(Doze.af + 0x0600); 
			else if (!flag.C && !flag.H && (((Doze.af >> 12) & 0x000f) >= 0x000A)
			&& (((Doze.af >> 8) & 0x000f) <= 0x0009))
			{
				Doze.af = (unsigned short)(Doze.af + 0x6000); 
				flag.C = 1;
			}
			else if (!flag.C && !flag.H && (((Doze.af >> 12) & 0x000f) >= 0x0009)
			&& (((Doze.af >> 8) & 0x000f) >= 0x000a))
			{
				Doze.af = (unsigned short)(Doze.af + 0x6600); 
				flag.C = 1;
				flag.H = 1;
			}
			else if (!flag.C && flag.H && (((Doze.af >> 12) & 0x000f) >= 0x000a)
			&& (((Doze.af >> 8) & 0x000f) <= 0x0003))
			{
				Doze.af = (unsigned short)(Doze.af + 0x6600); 
				flag.C = 1;
			}
			else if (flag.C && !flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0002)
			&& (((Doze.af >> 8) & 0x000f) <= 0x0009))
				Doze.af = (unsigned short)(Doze.af + 0x6000); 
			else if (flag.C && !flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0002)
			&& (((Doze.af >> 8) & 0x000f) >= 0x000a))
			{
				Doze.af = (unsigned short)(Doze.af + 0x6600); 
				flag.H = 1;
			}
			else if (flag.C && flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0003)
			&& (((Doze.af >> 8) & 0x000f) <= 0x0003))
				Doze.af = (unsigned short)(Doze.af + 0x6600); 
		}
		else if (flag.N)
		{
			if (!flag.C && flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0008)
			&& (((Doze.af >> 8) & 0x000f) >= 0x0006))
				Doze.af = (unsigned short)(Doze.af + 0xfa00);
			else if (flag.C && !flag.H && (((Doze.af >> 12) & 0x000f) >= 0x0007)
			&& (((Doze.af >> 8) & 0x000f) <= 0x0009))
				Doze.af = (unsigned short)(Doze.af + 0xa000);
			else if (flag.C && flag.H && (((Doze.af >> 12) & 0x000f) <= 0x0007)
			&& (((Doze.af >> 12) & 0x000f) >= 0x0006) && (((Doze.af >> 8) & 0x000f) >= 0x0006))
				Doze.af = (unsigned short)(Doze.af + 0x9a00);
		}
		flag.S = ((Doze.af & 0x8000) == 0x8000) ? 1 : 0;
		flag.Z = ((Doze.af & 0xff00) == 0x0000) ? 1 : 0;
		parity_check((unsigned short)(Doze.af>>8));
		nDozeCycles-= 4;
		break;
	case  DEC_IX:
		Doze.ix = (unsigned short)(Doze.ix - 1);
		nDozeCycles-= 10; //6;
		break;
	case  DEC_IY:
		Doze.iy = (unsigned short)(Doze.iy - 1);
		nDozeCycles-= 10; //6;
		break;
	case  DEC_m_1:
		setRegVal(bus_pre.r1,Arith_sub8(getRegVal(bus_pre.r1),0x0001));		
		nDozeCycles-= 4;
		break;
	case  DEC_m_2:
		DozeWrite(Doze.hl, (unsigned char)Arith_sub8(DozeRead(Doze.hl),0x0001));		
		nDozeCycles-= 11;
		break;
	case  DEC_m_3:
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), 
			(unsigned char)Arith_sub8(DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))),0x0001));
		nDozeCycles-= 23; // 19;
		break;
	case  DEC_m_4:
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), 
			(unsigned char)Arith_sub8(DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))),0x0001));		
		nDozeCycles-= 23; // 19;
		break;
	case  DEC_ss:
		setRegPairVal_dd((unsigned char)bus_pre.dd1, (unsigned short)(getRegPairVal_dd(bus_pre.dd1) - 1) );
		nDozeCycles-= 6;
		break;
	case  DI:
		Doze.iff = 0x0000;
		nDozeCycles-= 4;
		break;
	case  DJNZ_e:
		tempreg = (unsigned short)((Doze.bc >> 8) - 0x0001);
		Doze.bc = (unsigned short)((tempreg << 8) + (Doze.bc & 0x00ff));
		if (tempreg != 0x0000)
		{
			Doze.pc = (unsigned short)(Doze.pc + sign_extend(bus_pre.n2));
			nDozeCycles-= 13;
		}
		else
			nDozeCycles-= 8;
		break;
	case  EI:
		//?? ////////////////////////////
		if (nDozeEi == 1)
		{
			Doze.iff = 0x0101;
			nDozeCycles-= 4;
		}
		else
		{
			if (Doze.iff != 0x0101)
			{
				nDozeEi = 2;
				Doze.iff = 0x0101;
				nDozeCycles -= 4;
			}
			else
			{
				Doze.iff = 0x0101;
				nDozeCycles-= 4;
			}
		}			
		break;
	case  EX_SP_HL:
// new modified
//		tempreg = (unsigned short)( (unsigned short)DozeRead(Doze.sp) 
//		+ (((unsigned short)DozeRead(++Doze.sp)) << 8 ) );
		tempreg = (unsigned short)DozeRead(Doze.sp);
		tempreg = (unsigned short)((((unsigned short)DozeRead((unsigned short)(Doze.sp+1))) << 8) + (tempreg & 0x00ff) );
		DozeWrite(Doze.sp, (unsigned char)(Doze.hl & 0x00ff));
		DozeWrite((unsigned short)(Doze.sp+1), (unsigned char)(Doze.hl >> 8));
		Doze.hl = tempreg;
		nDozeCycles-= 19;
		break;
	case  EX_SP_IX:
		tempreg = (unsigned short)DozeRead(Doze.sp);
		tempreg = (unsigned short)((((unsigned short)DozeRead((unsigned short)(Doze.sp+1))) << 8) + (tempreg & 0x00ff) );
		DozeWrite(Doze.sp, (unsigned char)(Doze.ix & 0x00ff));
		DozeWrite((unsigned short)(Doze.sp+1), (unsigned char)(Doze.ix >> 8));		
		Doze.ix = tempreg;
		nDozeCycles-= 23; // 19;
		break;
	case  EX_SP_IY:
		tempreg = (unsigned short)DozeRead(Doze.sp);
		tempreg = (unsigned short)((((unsigned short)DozeRead((unsigned short)(Doze.sp+1))) << 8) + (tempreg & 0x00ff) );
		DozeWrite(Doze.sp, (unsigned char)(Doze.iy & 0x00ff));
		DozeWrite((unsigned short)(Doze.sp+1), (unsigned char)(Doze.iy >> 8));		
		Doze.iy = tempreg;
		nDozeCycles-= 23; //19;
		break;
	case  EX_AF_AF:
		tempreg = Doze.af;
		Doze.af = Doze.af2;
		Doze.af2 = tempreg;
/*-------------------- Flag will not affect-------------------
		flag.C = (Doze.af & 0x01);			// Carry flag
		flag.N = (Doze.af & 0x02) >> 1;		// Add/Subtract flag
		flag.PV = (Doze.af & 0x04) >> 2;
		flag.no_use1 = (Doze.af & 0x08) >> 3;
		flag.H = (Doze.af & 0x10) >> 4;			// Half_carry flag
		flag.no_use2 = 	(Doze.af & 0x20) >> 5;
		flag.Z = (Doze.af & 0x40) >> 6;			// Zero flag
		flag.S = (Doze.af & 0x80) >> 7;			// Sign flag
--------------------------------------------------------------*/
		nDozeCycles-= 4;
		break;
	case  EX_DE_HL:
		tempreg = Doze.de;
		Doze.de = Doze.hl;
		Doze.hl = tempreg;
		nDozeCycles-= 4;
		break;
	case  EXX:
		tempreg = Doze.bc;
		Doze.bc = Doze.bc2;
		Doze.bc2 = tempreg;
		tempreg = Doze.de;
		Doze.de = Doze.de2;
		Doze.de2 = tempreg;
		tempreg = Doze.hl;
		Doze.hl = Doze.hl2;
		Doze.hl2 = tempreg;
		nDozeCycles-= 4;
		break;		
	case  HALT:
		Doze.pc--;
		tempreg=(unsigned short)((nDozeCycles>>2)+1);
		Doze.ir= (unsigned short)( ((Doze.ir+tempreg)&0x007f) | (Doze.ir&0xff80) ); // Increase R register
		nDozeCycles-=tempreg;
		break;
	case  IM0:
		Doze.im = 0;
		nDozeCycles-= 8; //4;
		break;
	case  IM1:
		Doze.im = 1;
		nDozeCycles-= 8; //4;
		break;
	case  IM2:
		Doze.im = 2;
		nDozeCycles-= 8; //4;
		break;
	case  IN_A_n:
		tempreg = DozeIn((unsigned short)((Doze.af & 0xff00) + bus_pre.n2));
		Doze.af = (unsigned short)((tempreg << 8) + (Doze.af & 0x00ff));
		nDozeCycles-= 11;
		break;
	case  IN_r_C:
		tempreg = DozeIn(Doze.bc);
		setRegVal(bus_pre.r3,tempreg);
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);	
		flag.N = 0;
		flag.H = 0;
		nDozeCycles-= 12; //8;
		break;
	case  INC_HL:
//		flag.C need not be affected, assume not
//		if (DozeRead(Doze.hl) == 0x7f) tempreg = 1;
//		else tempreg = 0;
		DozeWrite(Doze.hl, (unsigned char)Arith_add8(DozeRead(Doze.hl),0x0001));		
//		if (tempreg == 1) flag.PV = 1;
//		else flag.PV = 0;
		nDozeCycles-= 11;
		break;
	case  INC_IX_d:
//		flag.C need not be affected, assume not
//		if ( DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))) == 0x7f) tempreg = 1;
//		else tempreg = 0;
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), 
			(unsigned char)Arith_add8(DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))),0x0001));
//		if (tempreg == 1) flag.PV = 1;
//		else flag.PV = 0;
		nDozeCycles-= 23; //19;
		break;
	case  INC_IY_d:
//		flag.C need not be affected, assume not
//		if (DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))) == 0x7f) tempreg = 1;
//		else tempreg = 0;
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), 
			(unsigned char)Arith_add8(DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))),0x0001));		
//		if (tempreg == 1) flag.PV = 1;
//		else flag.PV = 0;
		nDozeCycles-= 23; // 19;
		break;
	case  INC_IX:
			Doze.ix = (unsigned short)(Doze.ix + 1);
			nDozeCycles-= 10; // 6;
			break;
	case  INC_IY:
			Doze.iy = (unsigned short)(Doze.iy + 1);
			nDozeCycles-= 10; // 6;
			break;
	case  INC_r:
		setRegVal(bus_pre.r1,Arith_add8(getRegVal(bus_pre.r1),0x0001));		
		nDozeCycles-= 4;
		break;
	case  INC_ss:
			setRegPairVal_dd(bus_pre.dd1, (unsigned short)(getRegPairVal_dd(bus_pre.dd1) + 1) );
			nDozeCycles-= 6;
			break;
	case  IND:
		tempreg = DozeIn(Doze.bc);
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		Doze.hl--;
		if ((tempreg >> 7) == 0x0000)
			flag.N = 0;
		else flag.N = 1;
		if (((((Doze.bc&0x00ff)-1)&0x00ff) + (tempreg&0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
		nDozeCycles-= 16; //12;
		break;
	case  INDR:
		tempreg = DozeIn(Doze.bc);
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		Doze.hl--;
		if ((Doze.bc >> 8) != 0x0000)
		{
// new modified condition 2002/11/19			
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; //17;
		}
		else
			nDozeCycles-= 16; //12;
		if ((tempreg >> 7) == 0x0000)
			flag.N = 0;
		else flag.N = 1;
		if (((((Doze.bc&0x00ff)-1)&0x00ff) + (tempreg&0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
		break;
	case  INI:
		tempreg = DozeIn(Doze.bc);
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		Doze.hl++;
// undocumented setting flag
		if ((tempreg >> 7) == 0x0000)
			flag.N = 0;
		else flag.N = 1;
		if (((((Doze.bc+1)&0x00ff) + (tempreg&0x00ff)) >> 8) == 0x0001)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
		nDozeCycles-= 16; //12;
		break;
	case  INIR:
		tempreg = DozeIn(Doze.bc);
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		Doze.hl++;
		if ((Doze.bc >> 8) != 0x0000)
		{
// new modified condition 2002/11/19
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; //17;
		}
		else
			nDozeCycles-= 16; //12;
		if ((tempreg >> 7) == 0x0000)
			flag.N = 0;
		else flag.N = 1;
		if (((((Doze.bc&0x00ff)+1)&0x00ff) + (tempreg&0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
		break;
	case  JP_HL:
		Doze.pc = Doze.hl;
		nDozeCycles-= 4;
		break;
	case  JP_IX:
		Doze.pc = Doze.ix;
		nDozeCycles-= 8; // 4;
		break;
	case  JP_IY:
		Doze.pc = Doze.iy;
		nDozeCycles-= 8; // 4;
		break;
	case  JP_cc_nn:
		if (condition_check(bus_pre.r1))
			Doze.pc = bus_pre.nn1;
		nDozeCycles-= 10;
		break;
	case  JP_nn:
		Doze.pc = bus_pre.nn1;
		nDozeCycles-= 10;
		break;
	case  JR_NC_e:
		if (!flag.C)
		{
			Doze.pc = (unsigned short)(Doze.pc + sign_extend(bus_pre.n2));
			nDozeCycles-= 12;
		}
		else
			nDozeCycles-= 7;
		break;
	case  JR_C_e:
		if (flag.C)
		{
			Doze.pc = (unsigned short)(Doze.pc + sign_extend(bus_pre.n2));
			nDozeCycles-= 12;
		}
		else
			nDozeCycles-= 7;
		break;
	case  JR_e:
// 2s complement addition?		
		Doze.pc = (unsigned short)(Doze.pc + sign_extend(bus_pre.n2));
		nDozeCycles-= 12;
		break;
	case  JR_NZ_e:
		if (!flag.Z)
		{
			Doze.pc = (unsigned short)(Doze.pc + sign_extend(bus_pre.n2));
			nDozeCycles-= 12;
		}
		else
			nDozeCycles-= 7;
		break;
	case  JR_Z_e:
		if (flag.Z)
		{
			Doze.pc = (unsigned short)(Doze.pc + sign_extend(bus_pre.n2));
			nDozeCycles-= 12;
		}
		else
			nDozeCycles-= 7;
		break;
	case  LD_BC_A:
		DozeWrite(Doze.bc, (unsigned char)(Doze.af >> 8));
		nDozeCycles-= 7;
		break;
	case  LD_DE_A:
		DozeWrite(Doze.de, (unsigned char)(Doze.af >> 8));
		nDozeCycles-= 7;
		break;
	case  LD_HL_n:
		DozeWrite(Doze.hl, (unsigned char)(bus_pre.n2));
		nDozeCycles-= 10;
		break;		
	case  LD_HL_r:
		DozeWrite(Doze.hl, (unsigned char)getRegVal(bus_pre.r2));
		nDozeCycles-= 7;
		break;
	case  LD_IX_d_n:
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)(bus_pre.n4));
		nDozeCycles-= 19; // 15;
		break;	
	case  LD_IX_d_r:
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)getRegVal(bus_pre.r4));
		nDozeCycles-= 19;  //15
		break;		
	case  LD_IY_d_n:
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)(bus_pre.n4));
		nDozeCycles-= 19; //15;
		break;
	case  LD_IY_d_r:
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)getRegVal(bus_pre.r4));
		nDozeCycles-= 19; // 15;
		break;
	case  LD_nn_A:
		DozeWrite(bus_pre.nn1, (unsigned char)(Doze.af >> 8));
		nDozeCycles-= 13;
		break;
	case  LD_nn_dd:
		DozeWrite(bus_pre.nn2, (unsigned char)(getRegPairVal_dd(bus_pre.dd2) & 0x00ff));
		DozeWrite((unsigned short)(bus_pre.nn2+1), (unsigned char)(getRegPairVal_dd(bus_pre.dd2) >> 8));
		nDozeCycles-= 20; //16;
		break;		
	case  LD_nn_HL:
		DozeWrite(bus_pre.nn1, (unsigned char)(Doze.hl & 0x00ff));
		DozeWrite((unsigned short)(bus_pre.nn1+1), (unsigned char)(Doze.hl >> 8));
		nDozeCycles-= 20; // 16;
		break;
	case  LD_nn_IX:
		DozeWrite(bus_pre.nn2, (unsigned char)(Doze.ix & 0x00ff));
		DozeWrite((unsigned short)(bus_pre.nn2+1), (unsigned char)(Doze.ix >> 8));
		nDozeCycles-= 20; // 16;
		break;
	case  LD_nn_IY:
		DozeWrite(bus_pre.nn2, (unsigned char)(Doze.iy & 0x00ff));
		DozeWrite((unsigned short)(bus_pre.nn2+1), (unsigned char)(Doze.iy >> 8));
		nDozeCycles-= 20; //16;
		break;
	case  LD_A_BC:
		Doze.af = (unsigned short)( (((unsigned short)DozeRead(Doze.bc))<<8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 7;
		break;
	case  LD_A_DE:
		Doze.af = (unsigned short)( (((unsigned short)DozeRead(Doze.de))<<8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 7;
		break;
	case  LD_A_nn:
		Doze.af = (unsigned short)( (((unsigned short)DozeRead(bus_pre.nn1))<<8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 13;
		break;		
	case  LD_A_I:
		Doze.af = (unsigned short)( (Doze.ir & 0xff00) + (Doze.af & 0x00ff) );
		nDozeCycles-= 9; // 5;
		flag.S = ((Doze.ir & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.ir & 0xff00) == 0x0000)? 1:0;
		flag.H = 0;								// reset H flag
		flag.PV = ((Doze.iff & 0x0001) == 0x0000)? 0:1;	//set PV flag
		flag.N = 0;								// reset N flag
		break;
// flag PV still have problems
	case  LD_A_R:
		Doze.af = (unsigned short)( (Doze.ir << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 9; //5;
		flag.S = ((Doze.ir & 0x0080) == 0x0080)? 1:0;
		flag.Z = ((Doze.ir & 0x00ff) == 0x0000)? 1:0;
		flag.H = 0;								// reset H flag
		flag.PV = ((Doze.iff & 0x0001) == 0x0000)? 0:1;	//set PV flag
		flag.N = 0;	
		break;
// flag PV still have problems
	case  LD_dd_nn:	
		setRegPairVal_dd(bus_pre.dd2, (unsigned short)( (unsigned short)DozeRead(bus_pre.nn2) 
			+ ((unsigned short)DozeRead((unsigned short)(bus_pre.nn2+1)) << 8) ) );
		nDozeCycles-= 20; //16;
		break;
	case  LD_dd_nn2:
		setRegPairVal_dd(bus_pre.dd1, bus_pre.nn1);
		nDozeCycles-= 10;
		break;
	case  LD_HL_nn:
		Doze.hl = (unsigned short)( (unsigned short)DozeRead(bus_pre.nn1) + 
			((unsigned short)DozeRead((unsigned short)(bus_pre.nn1+1)) << 8) );
		nDozeCycles-= 16;
		break;
	case  LD_I_A:
		Doze.ir = (unsigned short)( (Doze.af & 0xff00) + (Doze.ir & 0x00ff) );
		nDozeCycles-= 9; //5;
		break;
	case  LD_IX_nn:
		Doze.ix = (unsigned short)( (unsigned short)DozeRead(bus_pre.nn2) + 
			((unsigned short)DozeRead((unsigned short)(bus_pre.nn2+1)) << 8) );
		nDozeCycles-= 20; // 16;
		break;
	case  LD_IX_nn2:
		Doze.ix = bus_pre.nn2;
		nDozeCycles-= 14; // 10;
		break;		
	case  LD_IY_nn:
		Doze.iy = (unsigned short)( (unsigned short)DozeRead(bus_pre.nn2) + 
			((unsigned short)DozeRead((unsigned short)(bus_pre.nn2+1)) << 8) );
		nDozeCycles-= 20; //16;
		break;
	case  LD_IY_nn2:
		Doze.iy = bus_pre.nn2;
		nDozeCycles-= 14; //10;
		break;
	case  LD_r_HL:
		setRegVal(bus_pre.r1, (unsigned short)DozeRead(Doze.hl));
		nDozeCycles-= 7;
		break;
	case  LD_r_IX_d:
		setRegVal(bus_pre.r3, (unsigned short)DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))));
		nDozeCycles-= 19; // 15;
		break;
	case  LD_r_IY_d:
		setRegVal(bus_pre.r3, (unsigned short)DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))));
		nDozeCycles-= 19; //15;
		break;
	case  LD_R_A:
		Doze.ir = (unsigned short)((Doze.af >> 8) + (Doze.ir & 0xff00));
		nDozeCycles-= 9; //5;
		break;
	case  LD_r_r:
		setRegVal(bus_pre.r1, getRegVal(bus_pre.r2));
		nDozeCycles-= 4;
		break;		
	case  LD_r_n:
		setRegVal(bus_pre.r1, bus_pre.n2);
		nDozeCycles-= 7;
		break;
	case  LD_SP_HL:
		Doze.sp = Doze.hl;
		nDozeCycles-= 6;
		break;
	case  LD_SP_IX:
		Doze.sp = Doze.ix;
		nDozeCycles-= 10; // 6;
		break;
	case  LD_SP_IY:
		Doze.sp = Doze.iy;
		nDozeCycles-= 10; //6;
		break;
	case  LDD:
		DozeWrite(Doze.de, DozeRead(Doze.hl));
		Doze.de--;
		Doze.hl--;
		Doze.bc--;
		flag.H = 0;
/*///////////////////////////////////////////////////
		flag.PV = ((Doze.bc - 1) != 0x0000)? 1:0;
///////////////////////////////////////////////////*/
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		flag.N = 0;
		nDozeCycles-= 16; //12;
		break;
	case  LDDR:
		DozeWrite(Doze.de, DozeRead(Doze.hl));
		Doze.de--;
		Doze.hl--;
		Doze.bc--;
		if (Doze.bc != 0x0000)
		{
// new modified condition 2002/11/19			
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; //17;
		}
		else
		{
			nDozeCycles-= 16; //12;		
		}
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		flag.H = 0;
		flag.N = 0;
		break;
	case  LDI:
		DozeWrite(Doze.de, DozeRead(Doze.hl));
		Doze.de++;
		Doze.hl++;
		Doze.bc--;
		flag.H = 0;
/*///////////////////////////////////////////////////
		flag.PV = ((Doze.bc - 1) != 0x0000)? 1:0;
///////////////////////////////////////////////////*/
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		flag.N = 0;
		nDozeCycles-= 16; //12;
		break;
	case  LDIR:
		DozeWrite(Doze.de, DozeRead(Doze.hl));
		Doze.de++;
		Doze.hl++;
		Doze.bc--;
		if (Doze.bc != 0x0000)
		{
// new modified condition 2002/11/19
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; //17;
		}
		else
		{
			nDozeCycles-= 16; //12;		
		}
		flag.PV = (Doze.bc != 0x0000)? 1:0;
		flag.H = 0;
		flag.N = 0;
		break;		
	case  NEG:
		Doze.af = (unsigned short)( (Arith_sub8(0x0000, (unsigned short)(Doze.af>>8)) << 8) 
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 8; //4;
		break;
	case  OR_s_1:
		Doze.af = (unsigned short)( (Arith_or((unsigned short)(Doze.af>>8), getRegVal(bus_pre.r2)) << 8)
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 4;
		break;
	case  OR_s_2:
		Doze.af = (unsigned short)( (Arith_or((unsigned short)(Doze.af>>8), (unsigned short)bus_pre.n2) << 8) 
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 7; //8;
		break;
	case  OR_s_3:
		Doze.af = (unsigned short)( (Arith_or((unsigned short)(Doze.af>>8), DozeRead(Doze.hl)) << 8)
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 7;
		break;
	case  OR_s_4:
		Doze.af = (unsigned short)( (Arith_or((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))) << 8)
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 19; // 15;
		break;
	case  OR_s_5:
		Doze.af = (unsigned short)( (Arith_or((unsigned short)(Doze.af>>8), DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))) << 8)
			+ (Doze.af & 0x00ff) );
		nDozeCycles-= 19; // 15;
		break;
	case  OTDR:
		tempreg = DozeRead(Doze.hl);
		DozeOut(Doze.bc, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		Doze.hl--;
		if ((Doze.bc >> 8) != 0x0000)
		{
// new modified condition 2002/11/19	
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; //17;
		}
		else
			nDozeCycles-= 16; //12;
		flag.Z = ((Doze.bc >> 8) == 0x0000)? 1:0;
// undocumented setting flag
		if ((tempreg + (Doze.hl & 0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
// undocumented setting flag
		if ((tempreg >> 7) == 0x0000)
			flag.N = 0;
		else flag.N = 1;
		break;
	case  OTIR:
		tempreg = DozeRead(Doze.hl);
		DozeOut(Doze.bc, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		Doze.hl++;
		if ((Doze.bc >> 8) != 0x0000)
		{
			Doze.pc = (unsigned short)(Doze.pc - 2);
			nDozeCycles-= 21; // 17;
		}
		else
			nDozeCycles-= 21; //12;
		flag.Z = ((Doze.bc >> 8) == 0x0000)? 1:0;
// undocumented setting flag
		if ((tempreg + (Doze.hl & 0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
// undocumented setting flag
		if ((tempreg >> 7) == 0x0000)
			flag.N = 0;
		else flag.N = 1;
		break;
	case  OUT_C_r:
		DozeOut(Doze.bc, (unsigned char)(getRegVal(bus_pre.r3)));
		nDozeCycles-= 12; //8;
		break;
	case  OUT_n_A:
		DozeOut((unsigned short)bus_pre.n2, (unsigned char)(Doze.af >> 8));
		nDozeCycles-= 11;
		break;
	case  OUTD:
		tempreg = DozeRead(Doze.hl);
		DozeOut(Doze.bc, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		flag.N = 1;
		Doze.hl--;
// undocumented setting flag
		if ((tempreg + (Doze.hl & 0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}		
		nDozeCycles-= 16; //12;
		break;
	case  OUTI:
		tempreg = DozeRead(Doze.hl);
		DozeOut(Doze.bc, (unsigned char)tempreg);
		Doze.bc = (unsigned short)(Doze.bc - 0x0100);
		flag.S = ((Doze.bc & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.bc & 0xff00) == 0x0000)? 1:0;
		flag.N = 1;
		Doze.hl++;
// undocumented setting flag
		if ((tempreg + (Doze.hl & 0x00ff)) > 255)
		{
			flag.C = 1;
			flag.H = 1;
		}
		else
		{
			flag.C = 0;
			flag.H = 0;
		}
		nDozeCycles-= 16; //12;
		break;
	case  POP_IX:
		Doze.ix = (unsigned short)DozeRead(Doze.sp);
		Doze.sp++;
		Doze.ix = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (Doze.ix & 0x00ff) );
		Doze.sp++;
		nDozeCycles-= 14; //10;
		break;
	case  POP_IY:
		Doze.iy = (unsigned short)DozeRead(Doze.sp);
		Doze.sp++;
		Doze.iy = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (Doze.iy & 0x00ff) );
		Doze.sp++;
		nDozeCycles-= 14; //10;
		break;
	case  POP_qq:
		tempreg = (unsigned short)DozeRead(Doze.sp);
		Doze.sp++;
		tempreg = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (tempreg & 0x00ff) );
		Doze.sp++;
		setRegPairVal_qq(bus_pre.qq1, tempreg);
		nDozeCycles-= 10;
		break;
	case  PUSH_IX:
		Doze.sp--;
		DozeWrite(Doze.sp, (unsigned char)(Doze.ix >> 8));
		Doze.sp--;
		DozeWrite(Doze.sp, (unsigned char)(Doze.ix & 0x00ff));
		nDozeCycles-= 15; // 11;
		break;
	case  PUSH_IY:
		Doze.sp--;
		DozeWrite(Doze.sp, (unsigned char)(Doze.iy >> 8));
		Doze.sp--;
		DozeWrite(Doze.sp, (unsigned char)(Doze.iy & 0x00ff));
		nDozeCycles-= 15; //11;
		break;
	case  PUSH_qq:
		Doze.sp--;
		DozeWrite(Doze.sp, (unsigned char)((getRegPairVal_qq(bus_pre.qq1) >> 8)&0x00ff));
		Doze.sp--;
		DozeWrite(Doze.sp, (unsigned char)(getRegPairVal_qq(bus_pre.qq1) & 0x00ff));
		nDozeCycles-= 11;
		break;
	case  RES_b_m_1:
		setRegVal(bus_pre.r4, resSpecBit(getRegVal(bus_pre.r4),bus_pre.r3));
		nDozeCycles-= 8; //4;
		break;
	case  RES_b_m_2:
		DozeWrite(Doze.hl, (unsigned char)resSpecBit(DozeRead(Doze.hl),bus_pre.r3));
		nDozeCycles-= 15; //11;
		break;
	case  RES_b_m_3:
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), 
			(unsigned char)resSpecBit(DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))), bus_pre.b4));
		nDozeCycles-= 23; //15;
		break;
	case  RES_b_m_4:
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), 
			(unsigned char)resSpecBit(DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))), bus_pre.b4));
		nDozeCycles-= 23; //15;
		break;
//new modified	
	case  RET:
		tempreg = (unsigned short)DozeRead(Doze.sp);
		Doze.sp++;
		Doze.pc = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (tempreg & 0x00ff) );
		Doze.sp++;
		nDozeCycles-= 10;
		break;
	case  RET_cc:
		if(condition_check(bus_pre.r1))
		{
			tempreg = (unsigned short)DozeRead(Doze.sp);
			Doze.sp++;
			Doze.pc = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (tempreg & 0x00ff) );
			Doze.sp++;
			nDozeCycles-= 11;
		}
		else
			nDozeCycles-= 5;
		break;
	case  RETI:
		Doze.pc = (unsigned short)DozeRead(Doze.sp);
		Doze.sp++;
		Doze.pc = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (Doze.pc & 0x00ff) );
		Doze.sp++;
		Doze.iff = (unsigned short)((Doze.iff >> 8) + (Doze.iff & 0xff00));
		nDozeCycles-= 14; //10;
		break;
	case  RETN:
		Doze.pc = (unsigned short)DozeRead(Doze.sp);
		Doze.sp++;
		Doze.pc = (unsigned short)((((unsigned short)DozeRead(Doze.sp)) << 8) + (Doze.pc & 0x00ff) );
		Doze.sp++;
		Doze.iff = (unsigned short)((Doze.iff >> 8) + (Doze.iff & 0xff00));
		nDozeCycles-= 14; //10;
		break;		
	case  RL_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0080) == 0x0000)
			tempreg2 = 0;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		if (tempreg2 == 1)
			flag.C = 1;
		else flag.C = 0;
		setRegVal(bus_pre.r4,tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  RL_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0080) == 0x0000)
			tempreg2 = 0;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		DozeWrite(Doze.hl,(unsigned char)tempreg);
		if (tempreg2 == 1)
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //11;
		break;
	case  RL_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			tempreg2 = 0 ;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)),(unsigned char)tempreg);
		if (tempreg2 == 1)	
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RL_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			tempreg2 = 0 ;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		if (tempreg2 == 1)	
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RLA:
		if ((Doze.af & 0x8000) == 0x0000)
			tempreg = 0;
		else tempreg = 1;
		Doze.af = (unsigned short)(((Doze.af << 1) & 0xfe00) + ((flag.C)?0x0100:0x0000) + (Doze.af & 0x00ff));
		if (tempreg == 1)
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		nDozeCycles-= 4;
		break;
	case  RLC_HL:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		DozeWrite(Doze.hl,(unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; // 11;
		break;
	case  RLC_IX_d:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RLC_IY_d:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RLC_r:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg << 1) & 0x00fe) + (flag.C?1:0));
		setRegVal(bus_pre.r4,tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;		
	case  RLCA:
		if ((Doze.af & 0x8000) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		Doze.af = (unsigned short)(((Doze.af << 1) & 0xfe00) + ((flag.C)?0x0100:0x0000) + (Doze.af & 0x00ff));
		flag.N = 0;
		flag.H = 0;
		nDozeCycles-= 4;
		break;
	case  RLD:
		tempreg = Doze.af;
		Doze.af = (unsigned short)((Doze.af & 0xf000) + 
			((unsigned short)(DozeRead(Doze.hl) & 0xf0) << 4) + (Doze.af & 0x00ff));
		DozeWrite(Doze.hl, (unsigned char)((DozeRead(Doze.hl) << 4) + ((tempreg & 0x0f00) >> 8)));
		flag.H = 0;
		flag.N = 0;
		sign_check((unsigned short)(Doze.af>>8));
		zero_check((unsigned short)(Doze.af>>8));
		parity_check((unsigned short)(Doze.af>>8));
		nDozeCycles-= 18; //14;
		break;
	case  RR_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0001) == 0x0000)
			tempreg2 = 0;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		if (tempreg2 == 1)
			flag.C = 1;
		else flag.C = 0;
		setRegVal(bus_pre.r4,tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  RR_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0001) == 0x0000)
			tempreg2 = 0;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		DozeWrite(Doze.hl,(unsigned char)tempreg);
		if (tempreg2 == 1)
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //11;
		break;
	case  RR_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			tempreg2 = 0 ;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		if (tempreg2 == 1)	
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RR_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			tempreg2 = 0 ;
		else tempreg2 = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		if (tempreg2 == 1)	
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RRA:
		if ((Doze.af & 0x0100) == 0x0000)
			tempreg = 0;
		else tempreg = 1;
		Doze.af = (unsigned short)(((Doze.af >> 1) & 0x7f00) + ((flag.C)?0x8000:0x0000) + (Doze.af & 0x00ff));
		if (tempreg == 1)	
			flag.C = 1;
		else flag.C = 0;
		flag.N = 0;
		flag.H = 0;
		nDozeCycles-= 4;
		break;
	case  RRC_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		setRegVal(bus_pre.r4,tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  RRC_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		DozeWrite(Doze.hl,(unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //11;
		break;
	case  RRC_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RRC_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  RRCA:
		if ((Doze.af & 0x0100) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		Doze.af = (unsigned short)(((Doze.af >> 1) & 0x7f00) + ((flag.C)?0x8000:0x0000) + (Doze.af & 0x00ff));
		flag.N = 0;
		flag.H = 0;
		nDozeCycles-= 4;
		break;
	case  RRD:
		tempreg = Doze.af;
		Doze.af = (unsigned short)((Doze.af & 0xf000) + 
			((unsigned short)(DozeRead(Doze.hl) & 0x0f) << 8) + (Doze.af & 0x00ff));
		DozeWrite(Doze.hl, (unsigned char)((DozeRead(Doze.hl) >> 4) + ((tempreg & 0x0f00) >> 4)));
		flag.H = 0;
		flag.N = 0;
		sign_check((unsigned short)(Doze.af>>8));
		zero_check((unsigned short)(Doze.af>>8));
		parity_check((unsigned short)(Doze.af>>8));
		nDozeCycles-= 18; // 14;
		break;
	case  RST_p:
		Doze.sp--;
		DozeWrite((Doze.sp),(unsigned char)(Doze.pc >> 8));
		Doze.sp--;
		DozeWrite((Doze.sp),(unsigned char)(Doze.pc & 0x00ff));
		switch(bus_pre.r1)
		{
		case 0x00: 
			Doze.pc = 0x0000;
			break;
		case 0x01:
			Doze.pc = 0x0008;
			break;
		case 0x02: 
			Doze.pc = 0x0010;
			break;
		case 0x03:
			Doze.pc = 0x0018;
			break;
		case 0x04: 
			Doze.pc = 0x0020;
			break;
		case 0x05:
			Doze.pc = 0x0028;
			break;
		case 0x06: 
			Doze.pc = 0x0030;
			break;
		case 0x07:
			Doze.pc = 0x0038;
			break;
		}
		nDozeCycles-= 11;
		break;
	case  SBC_A_s_1:
		tempreg = Arith_add8(getRegVal(bus_pre.r2) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 4;
		break;
	case  SBC_A_s_2:
		tempreg = Arith_add8((unsigned short)bus_pre.n2 ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 7; // 8;
		break;
	case  SBC_A_s_3:
		tempreg = Arith_add8((unsigned short)DozeRead(Doze.hl) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 7;
		break;
	case  SBC_A_s_4:
		tempreg = Arith_add8((unsigned short)DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))
			,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 19; //15;
		break;
	case  SBC_A_s_5:
		tempreg = Arith_add8((unsigned short)DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))
			,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		flag.no_use2 = flag.PV;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
					tempreg) << 8 ) + (Doze.af & 0x00ff) );
		flag.C = flag.C ^ flag.no_use1;
		flag.PV = flag.PV ^ flag.no_use2;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 19; //15;
		break;
	case  SBC_HL_ss:
		overflow_check16(getRegPairVal_dd(bus_pre.dd2) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use2 = flag.PV;
		tempreg = Arith_add16(getRegPairVal_dd(bus_pre.dd2) ,(unsigned short)(flag.C?0x0001:0x0000));
		flag.no_use1 = flag.C;
		tempreg2 = (unsigned char)(flag.H? 1:0);
		overflow_check16(Doze.hl, tempreg);
		flag.PV = flag.PV ^ flag.no_use2;
		Doze.hl = Arith_sub16(Doze.hl, tempreg);
		flag.C = flag.C ^ flag.no_use1;
		flag.S = ((Doze.hl & 0x8000) == 0x8000)? 1:0;
		flag.Z = ((Doze.hl & 0xffff) == 0)? 1:0;
		flag.H = ((unsigned char)flag.H ^ tempreg2)? 1:0;
		nDozeCycles-= 15; // 11;
		break;
	case  SCF:
		flag.C = 1;
		flag.H = 0;
		flag.N = 0;
		nDozeCycles-= 4;
		break;
	case  SET_b_HL:
		DozeWrite(Doze.hl, (unsigned char)setSpecBit(DozeRead(Doze.hl),bus_pre.r3));
		nDozeCycles-= 15; //11;
		break;
	case  SET_b_IX_d:
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), 
			(unsigned char)setSpecBit(DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d))),bus_pre.b4));
		nDozeCycles-= 23; //15;
		break;
	case  SET_b_IY_d:
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), 
			(unsigned char)setSpecBit(DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d))),bus_pre.b4));
		nDozeCycles-= 23; //15;
		break;
	case  SET_b_r:
		setRegVal(bus_pre.r4, setSpecBit(getRegVal(bus_pre.r4),bus_pre.r3));
		nDozeCycles-= 8; //4;
		break;
	case  SLA_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		setRegVal(bus_pre.r4, tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  SLA_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //11;
		break;
	case  SLA_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SLA_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SRA_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (tempreg & 0x0080));
		setRegVal(bus_pre.r4, tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  SRA_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (tempreg & 0x0080));
		DozeWrite(Doze.hl,(unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //11;
		break;
	case  SRA_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (tempreg & 0x0080));
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SRA_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)(((tempreg >> 1) & 0x007f) + (tempreg & 0x0080));
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SRL_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg >> 1) & 0x007f);
		setRegVal(bus_pre.r4, tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  SRL_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg >> 1) & 0x007f);
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //  11;
		break;
	case  SRL_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg >> 1) & 0x007f);
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SRL_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0001) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg >> 1) & 0x007f);
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SUB_s_1:
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
			getRegVal(bus_pre.r2)) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 4;
		break;
	case  SUB_s_2:
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
			(unsigned short)bus_pre.n2) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 7; // 8;
		break;
	case  SUB_s_3:
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8),
			DozeRead(Doze.hl)) << 8) + (Doze.af & 0x00ff));
		nDozeCycles-= 7;
		break;
	case  SUB_s_4:
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
			DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 19; //15;
		break;
	case  SUB_s_5:
		Doze.af = (unsigned short)( (Arith_sub8((unsigned short)(Doze.af>>8), 
			DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 19; //15;
		break;
	case  XOR_s_1:
		Doze.af = (unsigned short)( (Arith_xor((unsigned short)(Doze.af>>8), 
			getRegVal(bus_pre.r2)) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 4;
		break;	
	case  XOR_s_2:
		Doze.af = (unsigned short)( (Arith_xor((unsigned short)(Doze.af>>8), 
			(unsigned short)bus_pre.n2) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 7; //8;
		break;
	case  XOR_s_3:
		Doze.af = (unsigned short)( (Arith_xor((unsigned short)(Doze.af>>8), 
			DozeRead(Doze.hl)) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 7;
		break;
	case  XOR_s_4:
		Doze.af = (unsigned short)( (Arith_xor((unsigned short)(Doze.af>>8), 
			DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)))) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 19; //15;
		break;
	case  XOR_s_5:
		Doze.af = (unsigned short)( (Arith_xor((unsigned short)(Doze.af>>8), 
			DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)))) << 8) + (Doze.af & 0x00ff) );
		nDozeCycles-= 19; // 15;
		break;
/////////////// SLL //////////////////////////
	case  SLL_m_1:
		tempreg = getRegVal(bus_pre.r4);
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		tempreg++;
		setRegVal(bus_pre.r4, tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 8; //4;
		break;
	case  SLL_m_2:
		tempreg = DozeRead(Doze.hl);
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0;
		else flag.C = 1;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		tempreg++;
		DozeWrite(Doze.hl, (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 15; //11;
		break;
	case  SLL_m_3:
		tempreg = DozeRead((unsigned short)(Doze.ix+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg++;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		DozeWrite((unsigned short)(Doze.ix+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
	case  SLL_m_4:
		tempreg = DozeRead((unsigned short)(Doze.iy+sign_extend(bus_pre.d)));
		if ((tempreg & 0x0080) == 0x0000)
			flag.C = 0 ;
		else flag.C = 1;
		tempreg++;
		tempreg = (unsigned short)((tempreg << 1) & 0x00fe);
		DozeWrite((unsigned short)(Doze.iy+sign_extend(bus_pre.d)), (unsigned char)tempreg);
		flag.N = 0;
		flag.H = 0;
		sign_check(tempreg);
		zero_check(tempreg);
		parity_check(tempreg);
		nDozeCycles-= 23; //15;
		break;
///////////////////////////////////

	default: break;
	}

	if ((z80_ID != EX_AF_AF) && (z80_ID != POP_qq )  && (z80_ID != PUSH_qq ))
	{
		Doze.af = (unsigned short)( ( Doze.af & 0xff00 ) + ( ((unsigned short)flag.S<<7) + ((unsigned short)flag.Z<<6)
		+ ((unsigned short)flag.no_use2<<5) + ((unsigned short)flag.H<<4)
		+ ((unsigned short)flag.no_use1<<3) + ((unsigned short)flag.PV<<2)
		+ ((unsigned short)flag.N<<1) + ((unsigned short)flag.C) ) );
	}
}
