/*==========================================================================================*
|	Z80 micro instruction function															|
|																							|
|						Writen by SMS-IO Group (Tsung-Hao, Chen ; Tsung-Chi, Lin)			|
| ----------------------------------------------------------------------------------------- |
|	Date:																					|
|	11/11/2002	Original version established.												|
*==========================================================================================*/


#include "..\\mast\\doze.h"
#include "dozeint_554.h"
#include "micro_inst.h"
#include "DataValue.h"
#include "z80_I_run.h"

temp_reg t0123;

struct Fields
{
	unsigned char opcode;
	unsigned char Rd, Rs, Rt;
	unsigned char imm8;
	unsigned short imm16;

	unsigned char PC_disp;
	unsigned char F_mask;
	bool EOI;
};

unsigned short micro_sign_extend(unsigned char a)
{
	return (unsigned short)(( a >> 7 ) ? ( 0xff00 + a ) : a);
}

bool micro_parity_check(unsigned char opd)
{
	if ((((opd & 0x0080) >> 7)^
		((opd & 0x0040) >> 6)^
		((opd & 0x0020) >> 5)^
		((opd & 0x0010) >> 4)^
		((opd & 0x0008) >> 3)^
		((opd & 0x0004) >> 2)^
		((opd & 0x0002) >> 1)^
		(opd & 0x0001))==0x0000) return 1;
	else return 0;
}

bool micro_overflow_check(bool sign1, bool sign2, bool sign_result)
{
	// (+) - (-) == (-)
	if ( sign1==0 && sign2==1 && sign_result==1 && flag.N==1 ) return 1;
	// (-) - (+) == (+)
	else if ( sign1==1 && sign2==0 && sign_result==0 && flag.N==1 ) return 1;
	// (+) + (+) == (-)
	else if ( sign1==0 && sign2==0 && sign_result==1 && flag.N==0 ) return 1;
	// (-) + (-) == (+)
	else if ( sign1==1 && sign2==1 && sign_result==0 && flag.N==0 ) return 1;
	// no overflow
	else return 0;
}


unsigned short micro_get_reg(unsigned char reg)
{
	switch ( reg )
	{
	case 0x00:		// R0
		return 0;
	// 8-bit
	case 0x0f:		// A, 01111
		return micro_sign_extend( (unsigned char)(Doze.af >> 8) );
	case 0x0d:		// F, 01101
		return micro_sign_extend( (unsigned char)(Doze.af & 0x00ff) );
	case 0x01:		// B, 00001
		return micro_sign_extend( (unsigned char)(Doze.bc >> 8) );
	case 0x03:		// C, 00011
		return micro_sign_extend( (unsigned char)(Doze.bc & 0x00ff) );
	case 0x05:		// D, 00101
		return micro_sign_extend( (unsigned char)(Doze.de >> 8) );
	case 0x07:		// E, 00111
		return micro_sign_extend( (unsigned char)(Doze.de & 0x00ff) );
	case 0x09:		// H, 01001
		return micro_sign_extend( (unsigned char)(Doze.hl >> 8) );
	case 0x0B:		// L, 01011
		return micro_sign_extend( (unsigned char)(Doze.hl & 0x00ff) );
	case 0x04:		// I, 00100
		return micro_sign_extend( (unsigned char)(Doze.ir >> 8) );
	case 0x08:		// R, 01000
		return micro_sign_extend( (unsigned char)(Doze.ir & 0x00ff) );
	case 0x02:		// T0, 00010
		return micro_sign_extend( (unsigned char)(t0123.T10 & 0x00ff) );
	case 0x06:		// T1, 00110
		return micro_sign_extend( (unsigned char)(t0123.T10 >> 8) );
	case 0x0a:		// T2, 01010
		return micro_sign_extend( (unsigned char)(t0123.T32 & 0x00ff) );
	case 0x0e:		// T3, 01110
		return micro_sign_extend( (unsigned char)(t0123.T32 >> 8) );
	// 16-bit
	case 0x19:		// SP, 11001
		return Doze.sp;
	case 0x1c:		// AF, 11100
		return Doze.af;
	case 0x10:		// BC, 10000
		return Doze.bc;
	case 0x14:		// DE, 10100
		return Doze.de;
	case 0x18:		// HL, 11000
		return Doze.hl;
	case 0x11:		// IX, 10001
		return Doze.ix;
	case 0x15:		// IY, 10101
		return Doze.iy;
	case 0x12:		// T10, 10010
		return t0123.T10;
	case 0x1a:		// T32, 11010
		return t0123.T32;
	case 0x1f:		// AF', 11111
		return Doze.af2;
	case 0x13:		// BC', 10011
		return Doze.bc2;
	case 0x17:		// DE', 10111
		return Doze.de2;
	case 0x1b:		// HL', 11011
		return Doze.hl2;
	default:
		printf("Error when micro_get_reg!!\n");
		exit(1);
		return 0;
	}
}

void micro_write_reg(unsigned char reg, unsigned short value)
{
	switch ( reg )
	{
	case 0x00:		// R0
		// write nothing into reg file
		break;
	// 8-bit
	case 0x0f:		// A, 01111
		Doze.af = (unsigned short)(((value<<8)&0xff00) + (Doze.af & 0x00ff));
		break;
	case 0x0d:		// F, 01101
		Doze.af = (unsigned short)((value&0x00ff) + (Doze.af & 0xff00));
		break;
	case 0x01:		// B, 00001
		Doze.bc = (unsigned short)(((value<<8)&0xff00) + (Doze.bc & 0x00ff));
		break;
	case 0x03:		// C, 00011
		Doze.bc = (unsigned short)((value&0x00ff) + (Doze.bc & 0xff00));
		break;
	case 0x05:		// D, 00101
		Doze.de = (unsigned short)(((value<<8)&0xff00) + (Doze.de & 0x00ff));
		break;
	case 0x07:		// E, 00111
		Doze.de = (unsigned short)((value&0x00ff) + (Doze.de & 0xff00));
		break;
	case 0x09:		// H, 01001
		Doze.hl = (unsigned short)(((value<<8)&0xff00) + (Doze.hl & 0x00ff));
		break;
	case 0x0B:		// L, 01011
		Doze.hl = (unsigned short)((value&0x00ff) + (Doze.hl & 0xff00));
		break;
	case 0x04:		// I, 00100
		Doze.ir = (unsigned short)(((value<<8)&0xff00) + (Doze.ir & 0x00ff));
		break;
	case 0x08:		// R, 01000
		Doze.ir = (unsigned short)((value&0x00ff) + (Doze.ir & 0xff00));
		break;
	case 0x02:		// T0, 00010
		t0123.T10 = (unsigned short)((value&0x00ff) + (t0123.T10 & 0xff00));
		break;
	case 0x06:		// T1, 00110
		t0123.T10 = (unsigned short)(((value<<8)&0xff00) + (t0123.T10 & 0x00ff));
		break;
	case 0x0a:		// T2, 01010
		t0123.T32 = (unsigned short)((value&0x00ff) + (t0123.T32 & 0xff00));
		break;
	case 0x0e:		// T3, 01110
		t0123.T32 = (unsigned short)(((value<<8)&0xff00) + (t0123.T32 & 0x00ff));
		break;
	// 16-bit
	case 0x19:		// SP, 11001
		Doze.sp = value;  break;
	case 0x1c:		// AF, 11100
		Doze.af = value;  break;
	case 0x10:		// BC, 10000
		Doze.bc = value;  break;
	case 0x14:		// DE, 10100
		Doze.de = value;  break;
	case 0x18:		// HL, 11000
		Doze.hl = value;  break;
	case 0x11:		// IX, 10001
		Doze.ix = value;  break;
	case 0x15:		// IY, 10101
		Doze.iy = value;  break;
	case 0x12:		// T10, 10010
		t0123.T10 = value;  break;
	case 0x1a:		// T32, 11010
		t0123.T32 = value;  break;
	case 0x1f:		// AF', 11111
		Doze.af2 = value;  break;
	case 0x13:		// BC', 10011
		Doze.bc2 = value;  break;
	case 0x17:		// DE', 10111
		Doze.de2 = value;  break;
	case 0x1b:		// HL', 11011
		Doze.hl2 = value;  break;
	default:
		printf("Error when micro_write_reg!!\n");
		exit(1);	
	}
}

unsigned short micro_add8(unsigned short op1, unsigned short op2)
{
	int dest = op1 + op2;
	flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
	flag.H = ( ((op1&0x000f)+(op2&0x000f)) > 0x000f ) ? 1 : 0;
	flag.C = ( ((op1&0x00ff)+(op2&0x00ff)) > 0x00ff ) ? 1 : 0;
	flag.N = 0;
	flag.PV = micro_overflow_check( ((op1&0x0080)!=0)?1:0, ((op2&0x0080)!=0)?1:0, flag.S );
	return (unsigned short)(dest&0x0000ffff);
}

unsigned short micro_add16(unsigned short op1, unsigned short op2)
{
	int dest = op1 + op2;
	flag.S = ( (dest & 0x8000) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0xffff) == 0 ) ? 1 : 0;
	flag.H = ( ((op1&0x0fff)+(op2&0x0fff)) > 0x000f ) ? 1 : 0;
	flag.C = ( ((op1&0xffff)+(op2&0xffff)) > 0xffff ) ? 1 : 0;
	flag.N = 0;
	flag.PV = micro_overflow_check( ((op1&0x8000)!=0)?1:0, ((op2&0x8000)!=0)?1:0, flag.S );
	return (unsigned short)(dest&0x0000ffff);
}

unsigned short micro_sub8(unsigned short op1, unsigned short op2)
{
	int dest = op1 - op2;
	flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
	flag.H = ( (op1&0x000f)<(op2&0x000f) ) ? 1 : 0;
	flag.C = ((( (op1&0x00ff) + (((op2^0x00ff)&0x00ff)+1) )>>8) == 0x0000)? 1:0;
	//flag.C = ( (op1&0x00ff)<(op2&0x00ff) ) ? 1 : 0;
	flag.N = 1;
	flag.PV = micro_overflow_check( ((op1&0x0080)!=0)?1:0, ((op2&0x0080)!=0)?1:0, flag.S );
	return (unsigned short)(dest&0x0000ffff);
}

unsigned short micro_sub16(unsigned short op1, unsigned short op2)
{
	int dest = op1 - op2;
	flag.S = ( (dest & 0x8000) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0xffff) == 0 ) ? 1 : 0;
	flag.H = ( (op1&0x0fff)<(op2&0x0fff) ) ? 1 : 0;
	flag.C = ((( (op1&0xffff) + (((op2^0xffff)&0xffff)+1) )>>16) == 0x0000)? 1:0;
	//flag.C = ( (op1&0xffff)<(op2&0xffff) ) ? 1 : 0;
	flag.N = 1;
	flag.PV = micro_overflow_check( ((op1&0x8000)!=0)?1:0, ((op2&0x8000)!=0)?1:0, flag.S );
	return (unsigned short)(dest&0x0000ffff);
}

unsigned short micro_and(unsigned short op1, unsigned short op2)
{
	int dest = op1 & op2;
	flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
	flag.H = 1;
	flag.C = 0;
	flag.N = 0;
	flag.PV = micro_parity_check((unsigned char)dest);
	return (unsigned short)(dest&0x0000ffff);
}

unsigned short micro_or(unsigned short op1, unsigned short op2)
{
	int dest = op1 | op2;
	flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
	flag.H = 0;
	flag.C = 0;
	flag.N = 0;
	flag.PV = micro_parity_check((unsigned char)dest);
	return (unsigned short)(dest&0x0000ffff);
}

unsigned short micro_xor(unsigned short op1, unsigned short op2)
{
	int dest = op1 ^ op2;
	flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
	flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
	flag.H = 0;
	flag.C = 0;
	flag.N = 0;
	flag.PV = micro_parity_check((unsigned char)dest);
	return (unsigned short)(dest&0x0000ffff);
}

unsigned char micro_shiftrotate(unsigned char op1, unsigned char opcode)
{
	int dest;
	switch ( opcode )
	{
	case 0x00:		// RLC
	case 0x01:		// RLCA
		if ((op1 & 0x0080) == 0x0000) flag.C = 0;
		else flag.C = 1;
		dest = (((op1 << 1) & 0x00fe) + (flag.C?1:0));
		break;

	case 0x02:		// RRC
	case 0x03:		// RRCA
		if ((op1 & 0x0001) == 0x0000) flag.C = 0;
		else flag.C = 1;
		dest = (((op1 >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		break;

	case 0x04:		// RL
	case 0x05:		// RLA
		dest = (((op1 << 1) & 0x00fe) + (flag.C?1:0));
		if ((op1 & 0x0080) == 0x0000) flag.C = 0;
		else flag.C = 1;
		break;

	case 0x06:		// RR
	case 0x07:		// RRA
		dest = (((op1 >> 1) & 0x007f) + (flag.C?0x0080:0x0000));
		if ((op1 & 0x0001) == 0x0000) flag.C = 0;
		else flag.C = 1;
		break;

	case 0x08:		// SLA
	case 0x0b:		// SLL
		if ((op1 & 0x0080) == 0x0000) flag.C = 0;
		else flag.C = 1;
		dest = ((op1 << 1) & 0x00fe);
		break;

	case 0x09:		// SRA
		if ((op1 & 0x0001) == 0x0000) flag.C = 0;
		else flag.C = 1;
		dest = (((op1 >> 1) & 0x007f) + (op1 & 0x0080));
		break;

	case 0x0a:		// SRL
		if ((op1 & 0x0001) == 0x0000) flag.C = 0;
		else flag.C = 1;
		dest =((op1 >> 1) & 0x007f);
		break;

	default:
		printf("Error when micro_shiftrotate()!!\n");
		exit(1);
	}

	switch ( opcode )
	{
	case 0x00:		// RLC
	case 0x02:		// RRC
	case 0x04:		// RL
	case 0x06:		// RR
	case 0x08:		// SLA
	case 0x09:		// SRA
	case 0x0a:		// SRL
	case 0x0b:		// SLL
		flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
		flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
		flag.PV = micro_parity_check((unsigned char)dest);
		break;
	default:
		break;
	}


	flag.N = 0;
	flag.H = 0;
	return (unsigned char)dest;
}

inline void run_DAA(void)
{
	unsigned char temp = (unsigned char)((Doze.af >> 8) & 0x00ff);
	unsigned char high = (unsigned char)((temp >> 4) & 0x000f);
	unsigned char low = (unsigned char)(temp & 0x000f);

	switch ( (flag.N<<2) + (flag.C<<1) + (flag.H) )
	{
	case 0x0:
		if ( high>=0x0 && high<=0x8 && low>=0xA && low<=0xF ) 
		{  temp += 0x06;  flag.C = 0;  flag.H = 1;  }
		else if ( high>=0xA && high<=0xF && low>=0x0 && low<=0x9 ) 
		{  temp += 0x60;  flag.C = 1;  flag.H = 0;  }
		else if ( high>=0x9 && high<=0xF && low>=0xA && low<=0xF ) 
		{  temp += 0x66;  flag.C = 1;  flag.H = 1;  }
		break;
	case 0x1:
		if ( high>=0x0 && high<=0x9 && low>=0x0 && low<=0x3 ) 
		{  temp += 0x06;  flag.C = 0;  flag.H  = 1;  }
		else if ( high>=0xA && high<=0xF && low>=0x0 && low<=0x3 ) 
		{  temp += 0x66;  flag.C = 1;  flag.H  = 1;  }
		break;
	case 0x2:
		if ( high>=0x0 && high<=0x2 && low>=0x0 && low<=0x9 ) 
		{  temp += 0x60;  flag.C = 1;  flag.H  = 0;  }
		else if ( high>=0x0 && high<=0x2 && low>=0xA && low<=0xF ) 
		{  temp += 0x66;  flag.C = 1;  flag.H  = 1;  }
		break;
	case 0x3:
		if ( high>=0x0 && high<=0x3 && low>=0x0 && low<=0x3 ) 
		{  temp += 0x66;  flag.C = 1;  flag.H  = 1;  }
		break;
	case 0x4:
		break;
	case 0x5:
		if ( high>=0x0 && high<=0x8 && low>=0x6 && low<=0xF ) 
		{  temp += 0xFA;  flag.C = 0;  flag.H  = 1;  }  // H?
		break;
	case 0x6:
		if ( high>=0x7 && high<=0xF && low>=0x0 && low<=0x9 ) 
		{  temp += 0xA0;  flag.C = 1;  flag.H  = 0;  }  // H?
		break;
	case 0x7:
		if ( high>=0x6 && high<=0x7 && low>=0x6 && low<=0xf ) 
		{  temp += 0x9A;  flag.C = 1;  flag.H  = 1;  }  // H?
		break;
	default:
		printf("Error in run_DAA();\n");
		break;
	}
	flag.S = ( (temp & 0x0080) == 0x80 ) ? 1 : 0;
	flag.Z = ( (temp & 0x00ff) == 0x00 ) ? 1 : 0;
	flag.PV = micro_parity_check(temp);
	Doze.af = (unsigned short)( ((int)temp<<8) + (Doze.af&0x00ff) );
}

inline void inc_r(void)
{
	if ((Doze.ir & 0x00fe) == 0x00fe)
		Doze.ir &= 0xff01;
	else
		Doze.ir+=2;
}




bool micro_inst(unsigned int mop_hi, unsigned int mop_lo)
// return flush or not, 1 for flush, 0 for not
{
	// decode 
	Fields field;
	field.PC_disp = (unsigned char)(( mop_hi >> 4 )& 0x07);
	field.F_mask = (unsigned char)((( mop_hi & 0xf ) << 4 ) + (( mop_lo >> 28 ) & 0xf));
	field.EOI = (bool)(( mop_lo >> 27 ) & 0x01);
	field.opcode = (unsigned char)(( mop_lo >> 21 ) & 0x3f);
	field.Rd = (unsigned char)(( mop_lo >> 16 ) & 0x1f);
	field.Rs = (unsigned char)(( mop_lo >> 11 ) & 0x1f);
	field.Rt = (unsigned char)(( mop_lo >> 6 ) & 0x1f);
	field.imm8 = (unsigned char)( mop_lo & 0xff );
	field.imm16 = (unsigned short)( mop_lo & 0xffff );

	// move F reg to flag
	flag.C = (Doze.af & 0x01);			// Carry flag
	flag.N = (Doze.af & 0x02) >> 1;		// Add/Subtract flag
	flag.PV = (Doze.af & 0x04) >> 2;
	flag.no_use1 = (Doze.af & 0x08) >> 3;
	flag.H = (Doze.af & 0x10) >> 4;			// Half_carry flag
	flag.no_use2 = 	(Doze.af & 0x20) >> 5;
	flag.Z = (Doze.af & 0x40) >> 6;			// Zero flag
	flag.S = (Doze.af & 0x80) >> 7;			// Sign flag

	// micro inst
	unsigned char temp_char;
	unsigned short op1, op2, dest;
	bool flush = 0;
	switch (field.opcode)
	{
	case 0x00:		// add Ra, Rb, Rc
		micro_write_reg( field.Rd, 
			micro_add8(micro_get_reg(field.Rs), micro_get_reg(field.Rt)) );
		nDozeCycles -= 4;
		break;

	case 0x01:		// addi Ra, Rb, IMM8
		micro_write_reg( field.Rd, 
			micro_add8(micro_get_reg(field.Rs), micro_sign_extend(field.imm8)) );
		nDozeCycles -= 4;
		break;

	case 0x02:		// sub Ra, Rb, Rc
		micro_write_reg( field.Rd, 
			micro_sub8(micro_get_reg(field.Rs), micro_get_reg(field.Rt)) );
		nDozeCycles -= 4;
		break;

	case 0x03:		// add16 RRa, RRb, RRc
		micro_write_reg( field.Rd, 
			micro_add16(micro_get_reg(field.Rs), micro_get_reg(field.Rt)) );
		nDozeCycles -= 4;
		break;

	case 0x04:		// addi16 RRa, RRb, IMM8
		micro_write_reg( field.Rd, 
			micro_add16(micro_get_reg(field.Rs), micro_sign_extend(field.imm8)) );
		nDozeCycles -= 4;
		break;

	case 0x05:		// sub16 Ra, Rb, Rc
		micro_write_reg( field.Rd, 
			micro_sub16(micro_get_reg(field.Rs), micro_get_reg(field.Rt)) );
		nDozeCycles -= 4;
		break;

	case 0x1a:		// subi Ra, Rb, IMM8
		micro_write_reg( field.Rd, 
			micro_sub8(micro_get_reg(field.Rs), micro_sign_extend(field.imm8)) );
		nDozeCycles -= 4;
		break;

	case 0x1b:		// subi16 Ra, Rb, IMM8
		micro_write_reg( field.Rd, 
			micro_sub16(micro_get_reg(field.Rs), micro_sign_extend(field.imm8)) );
		nDozeCycles -= 4;
		break;

	case 0x06:		// and RRRa, RRRb, RRRc
		micro_write_reg( field.Rd, 
			micro_and( micro_get_reg(field.Rs), micro_get_reg(field.Rt) ) );
		nDozeCycles -= 4;
		break;

	case 0x07:		// and RRRa, RRRb, imm8
		micro_write_reg( field.Rd, 
			micro_and( micro_get_reg(field.Rs), micro_sign_extend(field.imm8) ) );
		nDozeCycles -= 4;
		break;

	case 0x08:		// or RRRa, RRRb, RRRc
		micro_write_reg( field.Rd, 
			micro_or( micro_get_reg(field.Rs), micro_get_reg(field.Rt) ) );
		nDozeCycles -= 4;
		break;

	case 0x09:		// ori RRRa, RRRb, IMM8
		micro_write_reg( field.Rd, 
			micro_or( micro_get_reg(field.Rs), micro_sign_extend(field.imm8) ) );
		nDozeCycles -= 4;
		break;

	case 0x0a:		// xor RRRa, RRRb, RRRc
		micro_write_reg( field.Rd, 
			micro_xor( micro_get_reg(field.Rs), micro_get_reg(field.Rt) ) );
		nDozeCycles -= 4;
		break;

	case 0x0b:		// xori RRRa, RRRb, IMM8
		micro_write_reg( field.Rd, 
			micro_xor( micro_get_reg(field.Rs), micro_sign_extend(field.imm8) ) );
		nDozeCycles -= 4;
		break;

	case 0x0c:		// not RRRa, RRRb
		op1 = micro_get_reg(field.Rs);
		dest = (unsigned short)~op1;
		flag.H = 1;
		flag.N = 1;
		micro_write_reg( field.Rd, dest );
		nDozeCycles -= 4;
		break;

	case 0x0d:		// shiftrotate Ra, Rb, OP
		micro_write_reg( field.Rd, 
			micro_shiftrotate((unsigned char)micro_get_reg(field.Rs), field.imm8) );
		nDozeCycles -= 4;
		break;

	case 0x0e:		// get4 Ra, Rb, IMM8
		if ( field.imm8 != 0 ) micro_write_reg( field.Rd, 
			(unsigned short)((micro_get_reg(field.Rs) >> 4 ) & 0x000f) );
		else micro_write_reg( field.Rd, 
			(unsigned short)(micro_get_reg(field.Rs) & 0x000f) );
		nDozeCycles -= 4;
		break;

	case 0x0f:		// merge44 Ra, Rb, Rc
		dest = (unsigned short)( ((micro_get_reg(field.Rs)<<4)&0x00f0)
			+ (micro_get_reg(field.Rt)&0x000f) );		
		micro_write_reg( field.Rd, (unsigned short)dest );
		flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
		flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
		flag.H = 0;
		flag.N = 0;
		flag.PV = micro_parity_check((unsigned char)dest);
		nDozeCycles -= 4;
		break;

	case 0x10:		// mvPC RRa
		micro_write_reg( field.Rd, Doze.pc );
		nDozeCycles -= 4;
		break;

	case 0x1c:		// mvIFF RRRa, IMM8
		if ( field.imm8 == 1 ) dest = (unsigned short)(Doze.iff & 0x00ff);
		else if ( field.imm8 == 2 ) dest = (unsigned short)((Doze.iff >> 8) & 0x00ff);
		else {
			printf("Error when mvIFF RRRa, IMM8!!\n");
			exit(1);  }
		micro_write_reg( field.Rd, dest );
		nDozeCycles -= 4;
		break;

	case 0x11:		// DAA
		run_DAA();
		nDozeCycles -= 4;
		break;

	case 0x12:		// getbit Ra, Rb, IMM8
		dest = (unsigned short)((micro_get_reg(field.Rs) >> field.imm8)&0x0001);
		if ( field.imm8 >=8 ) {
			printf("Error when getbit Ra, Rb, IMM8!!\n");
			exit(1);  }
		flag.Z = (dest == 0x0000)? 1:0;
		flag.H = 1;
		flag.N = 0;
		micro_write_reg( field.Rd, dest );
		nDozeCycles -= 4;
		break;

	case 0x13:		// ngetbit Ra, Rb, IMM8
		dest = (unsigned short)((~(micro_get_reg(field.Rs) >> field.imm8))&0x0001);
		if ( field.imm8 >=8 ) {
			printf("Error when ngetbit Ra, Rb, IMM8!!\n");
			exit(1);  }
		flag.Z = (dest == 0x0000)? 1:0;
		flag.H = 1;
		flag.N = 0;
		micro_write_reg( field.Rd, dest );
		nDozeCycles -= 4;
		break;

	case 0x14:		// setbit Ra, Rb, IMM8
		op1 = micro_get_reg(field.Rd);
		op2 = micro_get_reg(field.Rs);
		if ( field.imm8 >= 8 ) {
			printf("Error when setbit Ra, Rb, IMM8!!\n");
			exit(1);  }
		if ( op2 != 0 ) dest = (unsigned short)( (op1 | (0x01 << field.imm8)) & 0x00ff );
		else dest = (unsigned short)( (op1 & (~(0x01 << field.imm8))) & 0x00ff );
		micro_write_reg( field.Rd, dest );
		nDozeCycles -= 4;
		break;

	case 0x15:		// nsetbit Ra, Rb, IMM8
		op1 = micro_get_reg(field.Rd);
		op2 = micro_get_reg(field.Rs);
		if ( field.imm8 >= 8 ) {
			printf("Error when nsetbit Ra, Rb, IMM8!!\n");
			exit(1);  }
		if ( op2 == 0 ) dest = (unsigned short)( (op1 | (0x01 << field.imm8)) & 0x00ff );
		else dest = (unsigned short)( (op1 & (~(0x01 << field.imm8))) & 0x00ff );
		micro_write_reg( field.Rd, dest );
		nDozeCycles -= 4;
		break;

	case 0x20:		// j IMM16
		Doze.pc = field.imm16;
		nDozeCycles -= 4;
		break;

	case 0x21:		// jr RRa
		Doze.pc = micro_get_reg(field.Rd);
		nDozeCycles -= 4;
		break;

	case 0x22:		// jc RRRa, IMM16
		op1 = micro_get_reg(field.Rd);
		if ( op1 != 0 ) {  Doze.pc = field.imm16;  flush = 1;  }
		nDozeCycles -= 4;
		break;

	case 0x23:		// Jrc RRRa, RRb
		op1 = micro_get_reg(field.Rd);
		if ( op1 != 0 ) {  Doze.pc = micro_get_reg(field.Rs);  flush = 1;  }
		nDozeCycles -= 4;
		break;

	case 0x24:		// bne RRRa, RRRb, IMM8
		op1 = micro_get_reg(field.Rd);
		op2 = micro_get_reg(field.Rs);
		if ( op1 != op2 ) 
		{
			Doze.pc = (unsigned short)(Doze.pc + micro_sign_extend(field.imm8));
			flush = 1;
		}
		nDozeCycles -= 4;
		break;

	case 0x25:		// beq RRRa, RRRb, IMM8
		op1 = micro_get_reg(field.Rd);
		op2 = micro_get_reg(field.Rs);
		if ( op1 == op2 ) 
		{
			Doze.pc = (unsigned short)(Doze.pc + micro_sign_extend(field.imm8));
			flush = 1;
		}
		nDozeCycles -= 4;
		break;

	case 0x30:		// ld Ra, (RRb+IMM8)
		micro_write_reg( field.Rd, 
			DozeRead((unsigned short)(micro_get_reg(field.Rs) 
			+ micro_sign_extend(field.imm8))) );
		nDozeCycles -= 4;
		break;

	case 0x31:		// st Ra, (RRb+IMM8)
		DozeWrite( (unsigned short)(micro_get_reg(field.Rs) 
			+ micro_sign_extend(field.imm8)), 
			(unsigned char)micro_get_reg(field.Rd) );
		nDozeCycles -= 4;
		break;

	case 0x16:		// limm RRRa, IMM16
		micro_write_reg( field.Rd, field.imm16 );
		nDozeCycles -= 4;
		break;

	case 0x17:		// EI
		if ( nDozeEi!=1 && Doze.iff!=0x0101 ) nDozeEi = 2;
		Doze.iff = 0x0101;
		nDozeCycles -= 4;
		break;

	case 0x18:		// DI
		Doze.iff = 0x0000;
		nDozeCycles -= 4;
		break;

	case 0x19:		// im IMM16
		if ( field.imm16 >=3 ) 
			printf("Error when IM IMM16!!\n");
		Doze.im = (unsigned char)field.imm16;
		nDozeCycles -= 4;
		break;

	case 0x32:		// in Ra, (Rb+IMM8)
		dest = DozeIn( (unsigned short)( (unsigned char)(micro_get_reg(field.Rs)&0xff)
			+ field.imm8 ) );
		micro_write_reg( field.Rd, dest );
		flag.S = ( (dest & 0x0080) != 0 ) ? 1 : 0;
		flag.Z = ( (dest & 0x00ff) == 0 ) ? 1 : 0;
		flag.H = 0;
		flag.N = 0;
		flag.PV = micro_parity_check((unsigned char)dest);
		nDozeCycles -= 4;
		break;

	case 0x33:		// out Ra, (Rb+IMM8)
		DozeOut( (unsigned short)( (unsigned char)(micro_get_reg(field.Rs)&0xff)
			+ field.imm8 ), (unsigned char)micro_get_reg(field.Rd) );
		nDozeCycles -= 4;
		break;

	default:
		printf("Error: unrecognized micro instruction!!\n");
		exit(1);
	}


	// move Flag to F reg (masking)
	temp_char =  (unsigned char)( ((unsigned short)flag.S<<7) + ((unsigned short)flag.Z<<6) 
		+ ((unsigned short)flag.no_use2<<5) + ((unsigned short)flag.H<<4) 
		+ ((unsigned short)flag.no_use1<<3) + ((unsigned short)flag.PV<<2) 
		+ ((unsigned short)flag.N<<1) + ((unsigned short)flag.C) );
		
	Doze.af = (unsigned short)( ( ~field.F_mask & Doze.af ) 
		+ ( field.F_mask & temp_char ) );

//	if ( field.EOI ) inc_r();

	return flush;
}



