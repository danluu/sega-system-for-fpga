/*==========================================================================================*
|	Micro Instructions Execution															|
|																							|
|						Writen by					Tsung-Chi, Lin		(I/O group)			|
| ----------------------------------------------------------------------------------------- |
|	Date:																					|
|	11/20/2002	Original version established.												|
|	11/21/2002	Update Translation Table from xlator.v										|
*==========================================================================================*/

#include "..\\mast\\doze.h"
#include "DataValue.h"
#include "z80_I_ID.h"
#include "micro_inst.h"
#include "micro_ISA_ID.h"
#include "z80_uOP_run.h"
#include "stdio.h"
#include "..\\mast\\mastint.h"

//#include <iomanip>
//#include <fstream.h>
//ofstream out("file_stream.txt", ios::binary);

#ifdef TRACE
unsigned int inst_count = 0;
#endif

/////////39-bit Instructions//////////////
unsigned int xlate_hi[10], xlate_lo[10];//
//////////////////////////////////////////
void XLATE_CLEAR(void)
{
	for (int i=0; i<=9; i++)
	{
		xlate_hi[i] = 0;
		xlate_lo[i] = 0;
	}
}


void EMIT_PC_DISP(int inst, unsigned int PC_disp)
{
	xlate_hi[inst] = (PC_disp << 4) + (xlate_hi[inst] & 0x0f);
//	Doze.pc += PC_disp;
}


void EMIT_F_MASK(int inst, unsigned int F_mask)
{
	xlate_hi[inst] = (F_mask >> 4) + (xlate_hi[inst] & 0x70);
	xlate_lo[inst] = (F_mask << 28) + (xlate_lo[inst] & 0x0fffffff);
}

void EMIT_EOI(int inst)
{
	xlate_lo[inst] |= 0x08000000;
}

// extract z80 byte
unsigned int Z80_BYTE(unsigned int byte)
{
	switch(byte)
	{
    case 0:
      return bus_pre.n1;
	  break;
    case 1:
      return bus_pre.n2;
	  break;
    case 2:
      return bus_pre.n3;
	  break;
    case 3:
      return bus_pre.n4;
	  break;
    default: 
      return bus_pre.n1;
	  break;
	}
}

// 8bit z80 -> uop register conversion
// be careful so that z80 reg is not 110
// (will be converted into R0)
unsigned int REG_CONV8(unsigned int z80_reg)
{
	  if(z80_reg == 0x06)
		  return rR0;
	  else
		  return ((z80_reg << 1) + 1);		//{1'b0, z80_reg, 1'b1}
}

// 16bit conversion
unsigned int REG_CONV_CELP(unsigned int z80_reg)
{
	switch(z80_reg)
	{
		case 0: 
			return rBC;
			break;
		case 1: 
			return rDE;
			break;
		case 2: 
			return rHL;
			break;
		case 3: 
			return rSP;
			break;
		default: 
			return rR0;
			break;
	}
}

unsigned int REG_CONV_CELF(unsigned int z80_reg)
{
	switch(z80_reg)
	{
		case 0: 
			return rBC;
			break;
		case 1: 
			return rDE;
			break;
		case 2: 
			return rHL;
			break;
		case 3: 
			return rAF;
			break;
		default: 
			return rR0;
			break;
	}
}

unsigned int REG_CONV_CEXP(unsigned int z80_reg)
{
	switch(z80_reg)
	{
		case 0: 
			return rBC;
			break;
		case 1: 
			return rDE;
			break;
		case 2: 
			return rIX;
			break;
		case 3: 
			return rSP;
			break;
		default: 
			return rR0;
			break;
	}
}

unsigned int REG_CONV_CEYP(unsigned int z80_reg)
{
	switch(z80_reg)
	{
		case 0: 
			return rBC;
			break;
		case 1: 
			return rDE;
			break;
		case 2: 
			return rIY;
			break;
		case 3: 
			return rSP;
			break;
		default: 
			return rR0;
			break;
	}
}

// CC conversion, returns bit position
unsigned int Z80_CC_BPOS(unsigned int z80_cc)
{
	switch((z80_cc >> 1))
	{
		case 0: 
			return 0x06;	//= 3'b110;	// Z
			break;
		case 1: 
			return 0x00;	//= 3'b000;	// C
			break;
		case 2: 
			return 0x02;	//= 3'b010;	// P/V
			break;
		case 3: 
			return 0x07;	//= 3'b111;	// S
			break;
		default: 
			return 0x00;	//= 3'b000;
			break;
	}
}

// uop EMIT routines ////////////////////////////////////
void EMIT_INST_RRR(int inst, unsigned int opcode, unsigned int Rd, unsigned int Rs, unsigned int Rt)
{
	xlate_hi[inst] = 0;
	xlate_lo[inst] = 0;
	xlate_lo[inst] = (opcode << 21) + (Rd << 16) + (Rs << 11) + (Rt << 6);
	//inst = 12'b000000000000,opcode,Rd,Rs,Rt,6'b000000};
}

void EMIT_INST_RRI(int inst, unsigned int opcode, unsigned int Rd, unsigned int Rs, int IMM)
{
	xlate_hi[inst] = 0;
	xlate_lo[inst] = 0;
	xlate_lo[inst] = (opcode << 21) + (Rd << 16) + (Rs << 11) + (IMM&0x00ff);
	//inst = {12'b000000000000,opcode,Rd,Rs,3'b000,IMM};
}


// IMM L/H are exchanged, according to z80 break;ianess
void EMIT_INST_RI(int inst, unsigned int opcode, unsigned int Rd, int IMM)
{
	xlate_hi[inst] = 0;
	xlate_lo[inst] = 0;
	xlate_lo[inst] = (opcode << 21) + (Rd << 16) + ((IMM&0x00ff)<<8) + ((IMM&0xff00)>>8);
	//inst = {12'b000000000000,opcode,Rd,IMM[7:0],IMM[15:8]};
}

int xlate_valid;
void XLATE_VALID_SET(int a)
{	xlate_valid = a;}

///////////////////////////////////////////////////////////
// xlator_core in xlator
///////////////////////////////////////////////////////////
void uINSTR_RUN(unsigned char z80_I_ID)
{

////////////////// Output //////////////////
#ifdef TRACE
	static FILE* uop_trace = fopen("chi_uop_trace.txt", "w");
	static FILE* z80_trace = fopen("chi_z80_trace.txt", "w");
//	static unsigned int inst_count = 0;
	inst_count++;
#endif
////////////////////////////////////////////



  XLATE_CLEAR();
  switch(z80_I_ID)
  {
    case NOP: ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;

	case ADC_A_s_1: //A, r//////////////////////////////////////////////////
      
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRR(xlate1, ADD_op, rT0, rT0, REG_CONV8(bus_pre.r2));
        
        EMIT_INST_RRR(xlate2, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate2, 0xff);            //8'b11111111
        EMIT_EOI(2);
      break;
      
	case ADC_A_s_2: //A, n//////////////////////////////////////////////////
      
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, bus_pre.n2);      
        
        EMIT_INST_RRR(xlate2, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate2, 0xff);            //8'b11111111
        EMIT_EOI(2);
      break;
      
	case ADC_A_s_3: //A, (HL)//////////////////////////////////////////////////
      
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rHL, 0);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  
            
        EMIT_INST_RRR(xlate3, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate3, 0xff);            //8'b11111111
        EMIT_EOI(3);
      break;
      
	case ADC_A_s_4: //A, (IX+d)//////////////////////////////////////////////////
      
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIX, bus_pre.n3);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  
            
        EMIT_INST_RRR(xlate3, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate3, 0xff);            //8'b11111111
        EMIT_EOI(3);
      break;
      
	case ADC_A_s_5: //A, (IY+d) //////////////////////////////////////////////////
      
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIY, bus_pre.n3);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  
            
        EMIT_INST_RRR(xlate3, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate3, 0xff);            //8'b11111111
        EMIT_EOI(3);
      break;
      
	case ADC_HL_ss: //HL<-HL+ss+CY//////////////////////////////////////////////////
      
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rT0, REG_CONV_CELP(bus_pre.dd2));
              
        EMIT_INST_RRR(xlate2, ADD16_op, rHL, rHL, rT32);
        EMIT_F_MASK(xlate2, 0xff);            //8'b11111111
        EMIT_EOI(2);
      break;
      
	case ADD_A_HL : //A<-A+(HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);
                
        EMIT_INST_RRR(xlate1, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        EMIT_EOI(1);
      break;
      
	case ADD_A_IX_d: //A<-A+(IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, Z80_BYTE(2));
        EMIT_PC_DISP(xlate0, 3);
                
        EMIT_INST_RRR(xlate1, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        EMIT_EOI(1);
      break;
      
	case ADD_A_IY_d: //A<-A+(IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, Z80_BYTE(2));
        EMIT_PC_DISP(xlate0, 3);
                
        EMIT_INST_RRR(xlate1, ADD_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        EMIT_EOI(1);
      break;
      
	case ADD_A_n : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI_op, rA, rA, Z80_BYTE(1));
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        EMIT_PC_DISP(xlate0, 2);	// NOV20
        EMIT_EOI(0);
      break;
      
	case ADD_A_r   : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rA, rA, REG_CONV8(bus_pre.r2));
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case ADD_HL_ss : //HL<-HL+ss//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, ADD16_op, rHL, rHL, REG_CONV_CELP(bus_pre.dd1));
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011
        
        EMIT_EOI(0);
      break;
      
	case ADD_IX_pp : //IX<-IX+pp//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, ADD16_op, rIX, rIX, REG_CONV_CEXP(bus_pre.dd2));
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011
        
        EMIT_EOI(0);
      break;
      
	case ADD_IY_rr : //IY<-IY+rr//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, ADD16_op, rIY, rIY, REG_CONV_CEYP(bus_pre.dd2));
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011
        
        EMIT_EOI(0);
      break;
      
	case AND_s_1   : //A<-A AND r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, AND_op, rA, rA, REG_CONV8(bus_pre.r2));
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case AND_s_2   : //A<-A AND n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, ANDI_op, rA, rA, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case AND_s_3   : //A<-A AND (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRR(xlate1, AND_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case AND_s_4   : //A<-A AND (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, AND_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case AND_s_5   : //A<-A AND (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, AND_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case BIT_b_HL  : //Z<-~(HL)b//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);

        EMIT_INST_RRI(xlate1, GETBIT_op, rR0, rT0, bus_pre.r3);
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_EOI(1);
      break;
      
	case BIT_b_IX_d: //Z<-~(IX+d)b//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);

        EMIT_INST_RRI(xlate1, GETBIT_op, rR0, rT0, bus_pre.b4);
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_EOI(1);
      break;
      
	case BIT_b_IY_d: //Z<-~(IY+d)b//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);

        EMIT_INST_RRI(xlate1, GETBIT_op, rR0, rT0, bus_pre.b4);
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_EOI(1);
      break;
      
	case BIT_b_r   : //Z<-~rb//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, GETBIT_op, rR0, REG_CONV8(bus_pre.r4), bus_pre.r3);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xfe);            //8'b11111110
        
        EMIT_EOI(0);
      break;
      
	case CALL_cc_nn: ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(7);	// NOV20
        
        EMIT_INST_RRI(xlate0, (((bus_pre.n1&0x08)==0x08) ? GETBIT_op : NGETBIT_op), rT0, rF, Z80_CC_BPOS(bus_pre.r1));
									// I_word[27] == 1'b'1
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRI(xlate1, BEQ_op, rT0, rR0, 0);	// go next z80 instruction if false
        // condition is true 
        EMIT_INST_RRI(xlate2, MVPC_op, rT10, 0, 0);	
        
        // put PC onto the stack
        EMIT_INST_RRI(xlate3, ST_op, rT1, rSP, -1);
        EMIT_INST_RRI(xlate4, ST_op, rT0, rSP, -2);	// NOV20
        
        EMIT_INST_RRI(xlate5, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI(xlate6, J_op, 0, bus_pre.nn1_i);
        EMIT_EOI(6);
      break;
      
	case CALL_nn   : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(5);	// NOV20
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);
        EMIT_PC_DISP(xlate0, 3);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);  // NOV20
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI(xlate4, J_op, 0, bus_pre.nn1_i);
        EMIT_EOI(4);
      break;
      
	case CCF       : //CY<-~CY//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_INST_RRI(xlate1, NSETBIT_op, rF, rT0, 0);
        EMIT_F_MASK(xlate1, 0x02);            //8'b00000010
        
		EMIT_EOI(1);
      break;
      
	case CP_s_1    : //A - r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, SUB_op, rR0, rA, REG_CONV8(bus_pre.r2));
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case CP_s_2    : //A - n////////////////////////////////////////////////// NOV20
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SUBI_op, rR0, rA, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case CP_s_3    : //A - (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRR(xlate1, SUB_op, rR0, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case CP_s_4    : //A-(IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rR0, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case CP_s_5    : //A-(IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rR0, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case CPD       : //A-(HL), HL--, BC--/////////////////////////////////////////////////
      
        XLATE_VALID_SET(6);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, -1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK(xlate2, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);	// read Z
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);
        EMIT_F_MASK(xlate4, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);  // set PV
        EMIT_EOI(5);
      break;
      
	case CPDR      : //CPD, if BC ==0 or A == (HL), terminate///////////////////////
      
        XLATE_VALID_SET(9);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, -1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK(xlate2, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);	// read Z
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);   // A - (HL)
        EMIT_F_MASK(xlate4, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);	// set PV. Until here, same as CPD
        
        EMIT_INST_RRI(xlate6, BEQ_op, rT0, rR0, 0);	// terminate if A-(HL) == 0
        
        EMIT_INST_RRI(xlate7, BEQ_op, rBC, rR0, 0);	// terminate if BC == 0
        
        EMIT_INST_RRI(xlate8, BEQ_op, rR0, rR0, -2);   // repeat always
        EMIT_EOI(8);
      break;
	case CPI       : //A-(HL), HL++, BC--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(6);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK(xlate2, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);
        EMIT_F_MASK(xlate4, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);               
        EMIT_EOI(5);
      break;
      
	case CPIR      : //CPI, if BC ==0 or A == (HL), terminate////////////////////////////
      
        XLATE_VALID_SET(9);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK(xlate2, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);
        EMIT_F_MASK(xlate4, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);
        
        EMIT_INST_RRI(xlate6, BEQ_op, rT0, rR0, 0);
        
        EMIT_INST_RRI(xlate7, BEQ_op, rBC, rR0, 0);
        
        EMIT_INST_RRI(xlate8, BEQ_op, rR0, rR0, -2);
        EMIT_EOI(8);
      break;
      
	case CPL       : //A <- ~A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, NOT_op, rA, rA, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0x3a);            //8'b00111010
        EMIT_EOI(0);
      break;
      
	case DAA       : //DAA//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, DAA_op, rA, rA, 0);	// F is taken care of by CORE
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xfd);            //8'b11111101	// NOV20
        EMIT_EOI(0);
      break;
      
	case DEC_IX    : //IX--/////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIX, rIX, -1);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case DEC_IY    : //IY--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIY, rIY, -1);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case DEC_m_1   : //r--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, SUBI_op, REG_CONV8(bus_pre.r1), REG_CONV8(bus_pre.r1), 1);  // NOV20
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xfe);            //8'b11111110
        
        EMIT_EOI(0);
      break;
      
	case DEC_m_2  : //(HL)--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRI(xlate1, SUBI_op, rT0, rT0, 1);  // NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case DEC_m_3   : // (IX+d)-- //////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRI(xlate1, SUBI_op, rT0, rT0, 1); // NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case DEC_m_4   : //(IY+d)--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRI(xlate1, SUBI_op, rT0, rT0, 1); // NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case DEC_ss    : //ss--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, REG_CONV_CELP(bus_pre.dd1), REG_CONV_CELP(bus_pre.dd1), -1);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case DI        : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, DI_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case DJNZ_e    : //Dec, and jump if not zero/////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, ADDI_op, rB, rB, -1);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, BNE_op, rB, rR0, bus_pre.n2);
        EMIT_EOI(1);
      break;
      
	case EI        : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, EI_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case EX_SP_HL  : //H <-> (SP+1), L <-> (SP)//////////////////////////
      
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ST_op, rL, rSP, 0);
        
        EMIT_INST_RRI(xlate3, ST_op, rH, rSP, 1);
        
        EMIT_INST_RRR(xlate4, ADD16_op, rHL, rT10, 0);	// NOV20
        
        EMIT_EOI(4);
      break;
      
	case EX_SP_IX  : //IXH <-> (SP+1), IXL <-> (SP)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(6);
        
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRR(xlate2, ADD16_op, rT32, rIX, 0);	// NOV20
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rSP, 0);	// NOV20
        
        EMIT_INST_RRI(xlate4, ST_op, rT3, rSP, 1);  // NOV20
        
        EMIT_INST_RRR(xlate5, ADD16_op, rIX, rT10, 0);  // NOV20 
        EMIT_EOI(5);
      break;
      
	case EX_SP_IY  : //IYH <-> (SP+1), IYL <-> (SP)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(6);
        
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRR(xlate2, ADD16_op, rT32, rIY, 0);  // NOV20
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rSP, 0);  // NOV20
        
        EMIT_INST_RRI(xlate4, ST_op, rT3, rSP, 1);  // NOV20
        
        EMIT_INST_RRR(xlate5, ADD16_op, rIY, rT10, 0);  // NOV20
        EMIT_EOI(5);
      break;
      
	case EX_AF_AF  : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        
        EMIT_INST_RRI(xlate0, ADD16_op, rT10, rAF, 0); // NOV20
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ADD16_op, rAF, rAFs, 0);  // NOV20
        
        EMIT_INST_RRI(xlate2, ADD16_op, rAFs, rT10, 0);  // NOV20
        EMIT_EOI(2);
      break;
      
	case EX_DE_HL  : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        
        EMIT_INST_RRI(xlate0, ADD16_op, rT10, rDE, 0);	// NOV20
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ADD16_op, rDE, rHL, 0);  // NOV20
        
        EMIT_INST_RRI(xlate2, ADD16_op, rHL, rT10, 0);  // NOV20
        EMIT_EOI(2);
      break;
      
	case EXX       : //exchange BC, DE, HL //////////////////////////////////////////////////
      
        XLATE_VALID_SET(9);
        
        EMIT_INST_RRI(xlate0, ADD16_op, rT10, rBC, 0); // NOV20
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ADD16_op, rBC, rBCs, 0); // NOV20
        
        EMIT_INST_RRI(xlate2, ADD16_op, rBCs, rT10, 0); // NOV20
        
        EMIT_INST_RRI(xlate3, ADD16_op, rT10, rDE, 0); // NOV20
        
        EMIT_INST_RRI(xlate4, ADD16_op, rDE, rDEs, 0); // NOV20
        
        EMIT_INST_RRI(xlate5, ADD16_op, rDEs, rT10, 0); // NOV20

        EMIT_INST_RRI(xlate6, ADD16_op, rT10, rHL, 0); // NOV20
        
        EMIT_INST_RRI(xlate7, ADD16_op, rHL, rHLs, 0); // NOV20
        
        EMIT_INST_RRI(xlate8, ADD16_op, rHLs, rT10, 0); // NOV20
        EMIT_EOI(8);
      break;
      
	case HALT      : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, BEQ_op, rR0, rR0, -1);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case IM0       : ////////////////////////////////////////////////////

		Doze.im = 0;
		XLATE_VALID_SET(0);
        EMIT_PC_DISP(xlate0, 2);

#ifdef TRACE
		// uop trace
		fprintf(uop_trace, "%.8x, PC %.4x:  ", inst_count, Doze.pc );
		fprintf(uop_trace, "    reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
			Doze.af, Doze.bc, Doze.de, Doze.hl, Doze.sp, Doze.ix, Doze.iy,
			Doze.af2, Doze.bc2, Doze.de2, Doze.hl2, t0123.T10, t0123.T32);
#endif


/*
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
*/      break;
      
	case IM1       : ////////////////////////////////////////////////////
 
		Doze.im = 1;
		XLATE_VALID_SET(0);
        EMIT_PC_DISP(xlate0, 2);

#ifdef TRACE
		// uop trace
		fprintf(uop_trace, "%.8x, PC %.4x:  ", inst_count, Doze.pc );
		fprintf(uop_trace, "    reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
			Doze.af, Doze.bc, Doze.de, Doze.hl, Doze.sp, Doze.ix, Doze.iy,
			Doze.af2, Doze.bc2, Doze.de2, Doze.hl2, t0123.T10, t0123.T32);
#endif

/*      XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
*/      break;
      
	case IM2       : ////////////////////////////////////////////////////
      
		Doze.im = 2;
		XLATE_VALID_SET(0);
        EMIT_PC_DISP(xlate0, 2);

#ifdef TRACE
		// uop trace
		fprintf(uop_trace, "%.8x, PC %.4x:  ", inst_count, Doze.pc );
		fprintf(uop_trace, "    reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
			Doze.af, Doze.bc, Doze.de, Doze.hl, Doze.sp, Doze.ix, Doze.iy,
			Doze.af2, Doze.bc2, Doze.de2, Doze.hl2, t0123.T10, t0123.T32);
#endif

/*        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
*/      break;
      
	case IN_A_n    : //A <- (n), noflags//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, IN_op, rA, rR0, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case IN_r_C    : //r <- (C) flag affected//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, IN_op, REG_CONV8(bus_pre.r3), rC, 0);
        EMIT_F_MASK(xlate0, 0xfe);            //8'b11111110
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case INC_HL    : //(HL)++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, 1);
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case INC_IX_d  : //(IX+d)++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, 1);
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case INC_IY_d  : //(IY+d)++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, 1);
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case INC_IX    : //IX++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIX, rIX, 1);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case INC_IY    : //IY++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIY, rIY, 1); // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case INC_r     : //r++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, ADDI_op, REG_CONV8(bus_pre.r1), REG_CONV8(bus_pre.r1), 1);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xfe);            //8'b11111110
        
        EMIT_EOI(0);
      break;
      
	case INC_ss    : //CELP ++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, REG_CONV_CELP(bus_pre.dd1), REG_CONV_CELP(bus_pre.dd1), 1);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case IND       : //(HL) <- (C), HL--, B-- /////???check flags???/////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0);
        EMIT_PC_DISP(xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1);	// NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, SUBI16_op, rHL, rHL, 1);  // NOV20
        EMIT_EOI(3);
      break;
      
	case INDR      : //do IND, terminate if B becomes 0// ??? check flags ???////////////////////////////////////////////////
      
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0);	// NOV20
        EMIT_PC_DISP(xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1);  // NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, SUBI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI(4);
      break;
      
	case INI       : //(HL) <- (C), HL++, B-- ///??? check flags ???///////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0);
        EMIT_PC_DISP(xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1); // NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rHL, rHL, 1);
        EMIT_EOI(3);
      break;
      
	case INIR      : // INI, terminate b becomes 0// ??? check flags ???////////////////////////////////////////////////
      
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0); // NOV20
        EMIT_PC_DISP(xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1); // NOV20
        EMIT_F_MASK(xlate1, 0xfe);            //8'b11111110
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rHL, rHL, 1);
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI(4);
      break;
      
	case JP_HL     : //PC <- HL//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RI(xlate0, JR_op, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);        
        EMIT_EOI(0);
      break;
      
	case JP_IX     : //PC <- IX//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RI(xlate0, JR_op, rIX, 0);
        EMIT_PC_DISP(xlate0, 2);        
        EMIT_EOI(0);
      break;
      
	case JP_IY     : //PC <- IY //////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RI(xlate0, JR_op, rIY, 0);
        EMIT_PC_DISP(xlate0, 2);        
        EMIT_EOI(0);
      break;
      
	case JP_cc_nn  : //PC<-nn if cc is true//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, (((bus_pre.n1&0x08)==0x08) ? GETBIT_op : NGETBIT_op), rT0, rF, Z80_CC_BPOS(bus_pre.r1));
									// I_word[27] == 1'b'1
        EMIT_PC_DISP(xlate0, 3);
        
        EMIT_INST_RI(xlate1, JC_op, rT0, bus_pre.nn1_i);
        EMIT_EOI(1);
      break;
      
	case JP_nn     : //PC<-nn//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RI(xlate0, J_op, 0, bus_pre.nn1_i);
        EMIT_PC_DISP(xlate0, 3);
        EMIT_EOI(0);
      break;
      
	case JR_NC_e   : //branch if C==0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, BEQ_op, rT0, rR0, bus_pre.n2);
        EMIT_EOI(1);
      break;
      
	case JR_C_e    : //branch if C!=0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, BNE_op, rT0, rR0, bus_pre.n2);
        EMIT_EOI(1);
      break;
      
	case JR_e      : //branch always//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, BEQ_op, rR0, rR0, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case JR_NZ_e   : //branch if Z==0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0x06);            //8'b00000110	// Z, NOV20
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI (xlate1, BEQ_op, rT0, rR0, bus_pre.n2);
        EMIT_EOI(1);
      break;
      
	case JR_Z_e    : //branch if Z!=0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0x06);            //8'b00000110 // Z, NOV20
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI (xlate1, BNE_op, rT0, rR0, bus_pre.n2);
        EMIT_EOI(1);
      break;
      
	case LD_BC_A   : //(BC)<-A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, rA, rBC, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_DE_A   : //(DE)<-A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, rA, rDE, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_HL_n   : //(HL)<-n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, ADDI_op, rT0, rR0, bus_pre.n2);	// NOV20
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ST_op, rT0, rHL, 0);
        EMIT_EOI(1);
      break;
      
	case LD_HL_r   : //(HL)<-r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, REG_CONV8(bus_pre.r2), rHL, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_IX_d_n : //(IX+d)<-n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, ADDI_op, rT0, rR0, bus_pre.n4);	// NOV20
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRI(xlate1, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(1);
      break;
      
	case LD_IX_d_r : //(IX+d)<-r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, REG_CONV8(bus_pre.r4), rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);
        EMIT_EOI(0);
      break;
      
	case LD_IY_d_n : //(IY+d)<-n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, ADDI_op, rT0, rR0, bus_pre.n4);	// NOV20
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRI(xlate1, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(1);
      break;
      
	case LD_IY_d_r : //(IY+d)<-r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, REG_CONV8(bus_pre.r4), rIY, bus_pre.n3); // NOV20
        EMIT_PC_DISP(xlate0, 3);
        EMIT_EOI(0);
      break;
      
	case LD_nn_A   : //(nn) <- A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn1_i);
        EMIT_PC_DISP(xlate0, 3);
        
        EMIT_INST_RRI(xlate1, ST_op, rA, rT10, 0);
        EMIT_EOI(1);
      break;
      
	case LD_nn_dd  : //(nn+1)<-ddh, (nn)<-ddl //////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rR0, REG_CONV_CELP(bus_pre.dd2));
        
        EMIT_INST_RRI(xlate2, ST_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rT10, 0);
        EMIT_EOI(3);
      break;
      
	case LD_nn_HL  : //(nn+1)<-H, (nn)<-L//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn1_i);
        EMIT_PC_DISP(xlate0, 3);
                
        EMIT_INST_RRI(xlate1, ST_op, rH, rT10, 1);
        
        EMIT_INST_RRI(xlate2, ST_op, rL, rT10, 0);
        EMIT_EOI(2);
      break;
      
	case LD_nn_IX  : //(nn+1)<-IXh, (nn)<-IXl//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rR0, rIX);
                
        EMIT_INST_RRI(xlate2, ST_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rT10, 0);
        EMIT_EOI(3);
      break;
      
	case LD_nn_IY  : //(nn+1)<-IYh, (nn)<-IYl//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rR0, rIY); // NOV20
                
        EMIT_INST_RRI(xlate2, ST_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rT10, 0);
        EMIT_EOI(3);
      break;
      
	case LD_A_BC   : //A<-(BC)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, rA, rBC, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_A_DE   : //A<-(DE)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, rA, rDE, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_A_nn   : //A<-(nn)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn1_i);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRI(xlate1, LD_op, rA, rT10, 0);
        EMIT_EOI(1);
      break;
      
	case LD_A_I    : //A<-I//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);			// NOV20
        EMIT_INST_RRR(xlate0, ADD_op, rA, rR0, rI);
        EMIT_F_MASK(xlate0, 0xfe);            //8'b11111110 
        // do something to get IFF2
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, MVIFF_op, rT0, rR0, 2);	// read iff2	NOV20
        
        EMIT_INST_RRI(xlate2, SETBIT_op, rF, rT0, 2);   // set PV with iff2  NOV20
        EMIT_EOI(2);			// NOV20
      break;
      
	case LD_A_R    : //A<-R//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);			// NOV20
        EMIT_INST_RRR(xlate0, ADD_op, rA, rR0, rR);
        EMIT_F_MASK(xlate0, 0xfe);            //8'b11111110 
        // do something to get IFF2
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, MVIFF_op, rT0, rR0, 2);	// read iff2	NOV20
        
        EMIT_INST_RRI(xlate2, SETBIT_op, rF, rT0, 2);   // set PV with iff2  NOV20
        EMIT_EOI(2);			// NOV20
      break;
      
	case LD_dd_nn  : //ddh<-(nn+1), ddl<-(nn) CELP//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, LD_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rT2, rT10, 0);
        
        EMIT_INST_RRR(xlate3, ADD16_op, REG_CONV_CELP(bus_pre.dd2), rT32, rR0);	// NOV20
        EMIT_EOI(3);
      break;
      
	case LD_dd_nn2  : //dd<-nn//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RI(xlate0, LIMM_op, REG_CONV_CELP(bus_pre.dd1), bus_pre.nn1_i);  // NOV20
        EMIT_PC_DISP(xlate0, 3);  // NOV20
        EMIT_EOI(0);
      break;
      
	case LD_HL_nn   : //H<-(nn+1), L<-(nn)////////////////check LD dd,(nn) (overlap)//////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn1_i);	// NOV20
        EMIT_PC_DISP(xlate0, 3);
                
        EMIT_INST_RRI(xlate1, LD_op, rH, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rL, rT10, 0);
        EMIT_EOI(2);
      break;
      
	case LD_I_A     : //I<-A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rI, rA, rR0);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case LD_IX_nn   : //IXh<-(nn+1), IXl<-(nn)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, LD_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rT2, rT10, 0);
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIX, rT32, rR0); // NOV20
        EMIT_EOI(3);
      break;
      
	case LD_IX_nn2  : //IX<-nn//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RI(xlate0, LIMM_op, rIX, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
        EMIT_EOI(0);
      break;
      
	case LD_IY_nn   : //IYh<-(nn+1), IYl<-(nn)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RI(xlate0, LIMM_op, rT10, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, LD_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rT2, rT10, 0);
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIY, rT32, rR0); // NOV20
        EMIT_EOI(3);
      break;
      
	case LD_IY_nn2  : //IY<-nn//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);		// NOV20
        EMIT_INST_RI(xlate0, LIMM_op, rIY, bus_pre.nn2_i);
        EMIT_PC_DISP(xlate0, 4);
        EMIT_EOI(0);
      break;
     
	case LD_r_HL    : //r<-(HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, REG_CONV8(bus_pre.r1), rHL, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_r_IX_d  : //r<-(IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, REG_CONV8(bus_pre.r3), rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);
        EMIT_EOI(0);
      break;
      
	case LD_r_IY_d  : //r<-(IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, REG_CONV8(bus_pre.r3), rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);
        EMIT_EOI(0);
      break;
      
	case LD_R_A     : //R<-A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR, rA, rR0);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case LD_r_r     : //r<-r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, REG_CONV8(bus_pre.r1), REG_CONV8(bus_pre.r2), rR0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_r_n     : //r<-n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI_op, REG_CONV8(bus_pre.r1), rR0, bus_pre.n2); // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case LD_SP_HL   : //SP<-HL//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD16_op, rSP, rR0, rHL);  // NOV20
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case LD_SP_IX   : //SP<-IX//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD16_op, rSP, rR0, rIX);  // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case LD_SP_IY   : //SP<-IY//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD16_op, rSP, rR0, rIY);	// NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case LDD        : //(DE)<-(HL), DE--, HL--, BC--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(9);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 0xc1);            //8'b11000001		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK(xlate2, 0x40);            //8'b01000000

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, -1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, -1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        EMIT_EOI(8);
      break;
      
	case LDDR       : //LDD, terminate if BC becomes 0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(10);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 0xc1);            //8'b11000001		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK(xlate2, 0x40);            //8'b01000000

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, -1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, -1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        EMIT_EOI(8);
        
        EMIT_INST_RRI(xlate9, BNE_op, rBC, rR0, -2);
        EMIT_EOI(9);
      break;
      
	case LDI        : //(DE)<-(HL), DE++, HL++, BC--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(9);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 0xc1);            //8'b11000001		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK(xlate2, 0x40);            //8'b01000000

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, 1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        EMIT_EOI(8);
      break;
      
	case LDIR       : //LDI, terminate if BC == 0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(10);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 0xc1);            //8'b11000001		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK(xlate2, 0x40);            //8'b01000000

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, 1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
 //       EMIT_EOI(8);
        
        EMIT_INST_RRI(xlate9, BNE_op, rBC, rR0, -2);
        EMIT_EOI(9);
      break;
      
	case NEG        : //A <- 0 - A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, SUB_op, rA, rR0, rA);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        EMIT_EOI(0);
      break;
      
	case OR_s_1   : //A<-A OR r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, OR_op, rA, rA, REG_CONV8(bus_pre.r2));
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case OR_s_2   : //A<-A OR n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, ORI_op, rA, rA, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case OR_s_3   : //A<-A OR (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRR(xlate1, OR_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case OR_s_4   : //A<-A OR (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, OR_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case OR_s_5   : //A<-A OR (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, OR_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case OTDR       : //(C)<-(HL), HL--, B--, repeat until B=0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK(xlate1, 0x42);            //8'b01000010

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, -1);	// NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI(4);
      break;
      
	case OTIR       : //(C)<-(HL), HL++, B--, repeat until B==0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK(xlate1, 0x42);            //8'b01000010

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, 1);  // NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI(4);
      break;
      
	case OUT_C_r    : //(C)<-r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, OUT_op, REG_CONV8(bus_pre.r3), rC, 0);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case OUT_n_A    : //(n) <- A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, OUT_op, rA, rR0, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case OUTD       : //(C)<-(HL), B--, HL--//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK(xlate1, 0x42);            //8'b01000010

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, -1);  // NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        EMIT_EOI(3);
      break;
      
	case OUTI       : //(C)<-(HL), B--, HL++//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK(xlate1, 0x42);            //8'b01000010

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        EMIT_EOI(3);
      break;
      
	case POP_IX     : //IXh<-(SP+1), IXl<-(SP), SP=SP+2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIX, rT10, rR0);  // NOV20
        EMIT_EOI(3);
      break;
      
	case POP_IY     : //IYh<-(SP+1), IYl<-(SP), SP=SP+2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIY, rT10, rR0);  // NOV20
        EMIT_EOI(3);
      break;
      
	case POP_qq     : //qqh<=(SP+1), qql<=(SP), SP=SP+2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RRR(xlate3, ADD16_op, REG_CONV_CELF(bus_pre.dd1), rT10, rR0);  // NOV20
        EMIT_EOI(3);
      break;
      
	case PUSH_IX    : //(SP-2)<-IXl, (SP-1)<-IXh, SP--2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRR(xlate0, ADD16_op, rT10, rIX, rR0); // NOV20
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);  // NOV20
        EMIT_EOI(3);
      break;
      
	case PUSH_IY    : //(SP-2)<-IYl, (SP-1)<-IYh, SP--2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRR(xlate0, ADD16_op, rT10, rIY, rR0);  // NOV20
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);  // NOV20
        EMIT_EOI(3);
      break;
      
	case PUSH_qq    : //(SP-2)<-qql, (SP-1)<-qqh, SP--2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRR(xlate0, ADD16_op, rT10, REG_CONV_CELF(bus_pre.dd1), rR0); // NOV20
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);  //NOV20
        EMIT_EOI(3);
      break;
      
	case RES_b_m_1  : //rb<-0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SETBIT_op, REG_CONV8(bus_pre.r4), rR0, bus_pre.r3);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case RES_b_m_2  : //(HL)b<-0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rT0, rR0, bus_pre.r3);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case RES_b_m_3  : //(IX+d)b<-0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rT0, rR0, bus_pre.b4);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RES_b_m_4  : //(IY+d)b<-0//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rT0, rR0, bus_pre.b4);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RET        : //PCl<-(SP), PCh<-(SP+1), SP++2//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT1, rSP, 1);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RI(xlate3, JR_op, rT10, 0);
        EMIT_EOI(3);
      break;
      
	case RET_cc     : //if cc is true, do RET//////////////////////////////////////////////////
      
        XLATE_VALID_SET(6);

        EMIT_INST_RRI(xlate0, (((bus_pre.n1&0x08)==0x08) ? GETBIT_op : NGETBIT_op), rT0, rF, Z80_CC_BPOS(bus_pre.r1));
									// I_word[27] == 1'b'1
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, BEQ_op, rT0, rR0, 0);  // if false, goto next inst

        EMIT_INST_RRI(xlate2, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate3, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate4, ADDI16_op, rSP, rSP, 2); // NOV20
        
        EMIT_INST_RI(xlate5, JR_op, rT10, 0);
        EMIT_EOI(5);
      break;
      
	case RETI       : //treat this same as RET/////////////should be investigated/////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT1, rSP, 1);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2); // NOV20
                
        EMIT_INST_RI(xlate3, JR_op, rT10, 0);
        EMIT_EOI(3);
      break;
      
	case RETN       : //treat this same as RET//////////////////reti + how to deal with iff?? ////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT1, rSP, 1);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2); // NOV20
        
        EMIT_INST_RI(xlate3, JR_op, rT10, 0);
        EMIT_EOI(3);
      break;
      
	case RL_m_1     : //RL r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x04);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_EOI(0);
      break;
      
	case RL_m_2     : //RL (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x04);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case RL_m_3     : //RL (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x04);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RL_m_4     : //RL (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3); // NOV20
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x04);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RLA        : //RLA A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 0x05);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011  // NOV20
        
        EMIT_EOI(0);
      break;
      
	case RLC_HL     : //RLC (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x00);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
       
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case RLC_IX_d   : //RLC (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x00);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RLC_IY_d   : ////////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x00);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RLC_r      : //RLC r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x00);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case RLCA       : //RLCA A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 0x01);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011  // NOV20
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case RLD        : //three way rotation////////////////////////////////////////////NOV20
      
        XLATE_VALID_SET(8);
        EMIT_INST_RRI(xlate0, LD_op, rT2, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, GET4_op, rT1, rT2, 1);
        
        EMIT_INST_RRI(xlate2, GET4_op, rT0, rT2, 0);
        
        EMIT_INST_RRI(xlate3, GET4_op, rT3, rA, 1);
        
        EMIT_INST_RRI(xlate4, GET4_op, rT2, rA, 0);
        
        EMIT_INST_RRR(xlate5, MERGE44_op, rA, rT3, rT1);
        EMIT_F_MASK(xlate5, 0xfe);            //8'b11111110
        
        EMIT_INST_RRR(xlate6, MERGE44_op, rT2, rT0, rT2);
        
        EMIT_INST_RRI(xlate7, ST_op, rT2, rHL, 0);
        EMIT_EOI(7);
      break;
      
	case RR_m_1     : //RR r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x06);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_EOI(0);
      break;
      
	case RR_m_2     : //RR (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x06);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case RR_m_3     : //RR (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x06);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RR_m_4     : //RR (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x06);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RRA        : //RRA A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 0x07);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011  // NOV20
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case RRC_m_1     : //RRC r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x02);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case RRC_m_2     : //RRC (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x02);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case RRC_m_3     : //RRC (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x02);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RRC_m_4     : //RRC (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3); // NOV20
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x02);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case RRCA       : //RRCA A//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 0x03);
        EMIT_F_MASK(xlate0, 0x3b);            //8'b00111011  // NOV20
        EMIT_PC_DISP(xlate0, 1);
        EMIT_EOI(0);
      break;
      
	case RRD        : //three way rotation//////////////////////////////////////////////// NOV20
      
        XLATE_VALID_SET(8);
        EMIT_INST_RRI(xlate0, LD_op, rT2, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRI(xlate1, GET4_op, rT1, rT2, 1);
        
        EMIT_INST_RRI(xlate2, GET4_op, rT0, rT2, 0);
        
        EMIT_INST_RRI(xlate3, GET4_op, rT3, rA, 1);
        
        EMIT_INST_RRI(xlate4, GET4_op, rT2, rA, 0);
        
        EMIT_INST_RRR(xlate5, MERGE44_op, rA, rT3, rT0);
        EMIT_F_MASK(xlate5, 0xfe);            //8'b11111110
        
        EMIT_INST_RRR(xlate6, MERGE44_op, rT2, rT2, rT1);
        
        EMIT_INST_RRI(xlate7, ST_op, rT2, rHL, 0);
        EMIT_EOI(7);
      break;
      
	case RST_p      : //(SP-1)<-PCH, (SP-2)<-PCL, PC<-????//////////////////////////////////////////////////
      
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);		// PC has been incremented already
        EMIT_PC_DISP(xlate0, 1);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);		// NOV20
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI(xlate4, J_op, 0, ((int)(bus_pre.r1)<<11));	// swapped IMM address
        EMIT_EOI(4);
      break;
      
	case SBC_A_s_1: //A<-A-r-CY//////////////////////////////////////////////////
      
        // cannot set transitive flags correctly
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 1);
        EMIT_INST_RRR(xlate1, ADD_op, rT0, rT0, REG_CONV8(bus_pre.r2));  // NOV20
        EMIT_INST_RRR(xlate2, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate2, 0xff);            //8'b11111111
        EMIT_EOI(2);
      break;
      
	case SBC_A_s_2: //A<-A-n-CY///////////////////////////////////////////////
      
        // flag problems
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, bus_pre.n2); // NOV20     
        EMIT_INST_RRR(xlate2, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate2, 0xff);            //8'b11111111
        EMIT_EOI(2);
      break;
      
	case SBC_A_s_3: //A<-A-(HL)-CY//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rHL, 0);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  // NOV20
            
        EMIT_INST_RRR(xlate3, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate3, 0xff);            //8'b11111111
        EMIT_EOI(3);
      break;
      
	case SBC_A_s_4: //A<-A-(IX+d)-CY//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIX, bus_pre.n3);  // NOV20
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  // NOV20
            
        EMIT_INST_RRR(xlate3, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate3, 0xff);            //8'b11111111
        EMIT_EOI(3);
      break;
      
	case SBC_A_s_5: //A<-A-(IY+d)-CY//////////////////////////////////////////////////
      
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIY, bus_pre.n3);  // NOV20
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  // NOV20
            
        EMIT_INST_RRR(xlate3, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate3, 0xff);            //8'b11111111
        EMIT_EOI(3);
      break;
      
	case SBC_HL_ss  : //HL<-HL-ss-CY//////////////////////////////////////////////////
      
        // flag problems
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP(xlate0, 2);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rT0, REG_CONV_CELP(bus_pre.dd2));  // NOV20
              
        EMIT_INST_RRR(xlate2, SUB16_op, rHL, rHL, rT32);
        EMIT_F_MASK(xlate2, 0xff);            //8'b11111111
        EMIT_EOI(2);
      break;
      
	case SCF        : //CY<-1//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, NSETBIT_op, rF, rR0, 0);
        EMIT_PC_DISP(xlate0, 1);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rF, rR0, 1);	// NOV20
		EMIT_INST_RRI(xlate2, SETBIT_op, rF, rR0, 4);	// NOV20

        EMIT_EOI(2);
      break;
      
	case SET_b_HL  : //(HL)b<-1//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);

        // EMIT_INST_RRI(xlate1, NSETBIT_op, rT1, rT0, bus_pre.r3);
		EMIT_INST_RRI(xlate1, NSETBIT_op, rT0, rR0, bus_pre.r3);

        // EMIT_INST_RRI(xlate2, ST_op, rT1, rHL, 0);
		EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);

        EMIT_EOI(2);
      break;
      
	case SET_b_IX_d: //(IX+d)b<-1//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);

        EMIT_INST_RRI(xlate1, NSETBIT_op, rT0, rR0, bus_pre.b4);

		EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SET_b_IY_d: //(IY+d)b<-1//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);

		EMIT_INST_RRI(xlate1, NSETBIT_op, rT0, rR0, bus_pre.b4);

		EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SET_b_r   : //rb<-1//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, NSETBIT_op, REG_CONV8(bus_pre.r4), rR0, bus_pre.r3);
        EMIT_PC_DISP(xlate0, 2);        
        EMIT_EOI(0);
      break;
      
	case SLA_m_1     : //SLA r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x08);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_EOI(0);
      break;
      
	case SLA_m_2     : //SLA (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x08);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case SLA_m_3     : //SLA (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x08);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SLA_m_4     : //SLA (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3); // NOV20
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x08);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SRA_m_1     : //SRA r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x09);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_EOI(0);
      break;
      
	case SRA_m_2     : //SRA (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x09);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case SRA_m_3     : //SRA (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x09);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SRA_m_4     : //SRA (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3); //NOV20
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x09);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SRL_m_1     : //SRL r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x0A);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111  // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_EOI(0);
      break;
      
	case SRL_m_2     : //SRL (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x0A);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI(2);
      break;
      
	case SRL_m_3     : //SRL (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x0A);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SRL_m_4     : //SRL (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3); // NOV20
        EMIT_PC_DISP(xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x0A);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI(2);
      break;
      
	case SUB_s_1   : //A<-A-r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, SUB_op, rA, rA, REG_CONV8(bus_pre.r2));
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case SUB_s_2   : //A<-A - n//////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, SUBI_op, rA, rA, bus_pre.n2); // NOV20
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case SUB_s_3   : //A<-A-(HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRR(xlate1, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case SUB_s_4   : //A<-A-(IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case SUB_s_5   : //A<-A-(IY+d)////////////////////////////////////////////////// // NOV20
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case XOR_s_1   : //A<-A xor r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, XOR_op, rA, rA, REG_CONV8(bus_pre.r2));
        EMIT_PC_DISP(xlate0, 1);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case XOR_s_2   : //A<-A xor n//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, XORI_op, rA, rA, bus_pre.n2);
        EMIT_PC_DISP(xlate0, 2);
        EMIT_F_MASK(xlate0, 0xff);            //8'b11111111
        
        EMIT_EOI(0);
      break;
      
	case XOR_s_3   : //A<-A xor (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP(xlate0, 1);

        EMIT_INST_RRR(xlate1, XOR_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case XOR_s_4   : //A<-A xor (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, XOR_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;
      
	case XOR_s_5   : //A<-A xor (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3);
        EMIT_PC_DISP(xlate0, 3);

        EMIT_INST_RRR(xlate1, XOR_op, rA, rA, rT0);
        EMIT_F_MASK(xlate1, 0xff);            //8'b11111111
        
        EMIT_EOI(1);
      break;

//////////////////////////////////
// UNDOCUMENTED
//////////////////////////////////
	case SLL_m_1     : //SLL r//////////////////////////////////////////////////
      
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(bus_pre.r4), REG_CONV8(bus_pre.r4), 0x0B);
        EMIT_F_MASK  (xlate0, 0xff);                 //8'b11111111  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      break;
      
	case SLL_m_2     : //SLL (HL)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x0B);
        EMIT_F_MASK  (xlate1, 0xff);                 //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      break;
      
	case SLL_m_3     : //SLL (IX+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, bus_pre.n3);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x0B);
        EMIT_F_MASK  (xlate1, 0xff);                 //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, bus_pre.n3);
        EMIT_EOI     (xlate2);
      break;
      
	case SLL_m_4     : //SLL (IY+d)//////////////////////////////////////////////////
      
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, bus_pre.n3); // NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 0x0B);
        EMIT_F_MASK  (xlate1, 0xff);                 //8'b11111111  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, bus_pre.n3);
        EMIT_EOI     (xlate2);
      break;



/*
//////////////////////////////////
// interrupt handler
//parameter INT_handler = 254, NMI_handler = 255;
//////////////////////////////////

	case INT_handler     : //(SP-1)<-PCh, (SP-2)<-PCl, SP--2, J 0x0038///////////NOV20
      
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);  
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI(xlate4, J_op, 0, 0x0038);
        EMIT_EOI(4);
      break;

	case NMI_handler     : //(SP-1)<-PCh, (SP-2)<-PCl, SP--2, J 0x0066///////////NOV20
      
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);  
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI(xlate4, J_op, 0, 0x0066);
        EMIT_EOI(4);
      break;
*/      
    default: ///////////////////////////////////////////////
      
		XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP(xlate0, 4);		// it is likely that the offset is 4
        EMIT_EOI(0);
      break;
	}





#ifdef TRACE
	// z80 trace
	fprintf(z80_trace, "%.8x, PC:%.4x, ", inst_count, Doze.o_pc);
#endif

	bool flush;
	for(int i=0;i<xlate_valid;i++)
	{
#ifdef TRACE
		// uop trace
		fprintf(uop_trace, "%.8x, PC %.4x:  ", inst_count, Doze.o_pc );
#endif
		
		flush = micro_inst(xlate_hi[i], xlate_lo[i]);

#ifdef TRACE
		// uop trace
		fprintf(uop_trace, "    reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
			Doze.af, Doze.bc, Doze.de, Doze.hl, Doze.sp, Doze.ix, Doze.iy,
			Doze.af2, Doze.bc2, Doze.de2, Doze.hl2, t0123.T10, t0123.T32);
#endif
		if ( flush ) break;
	}

#ifdef TRACE
	// z80 trace
	fprintf(z80_trace, "%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
		Doze.af, Doze.bc, Doze.de, Doze.hl, Doze.sp, Doze.ix, Doze.iy,
			Doze.af2, Doze.bc2, Doze.de2, Doze.hl2, t0123.T10, t0123.T32);
	// memtrace

//	if ( inst_count == 0x2bc0 ) 
//	{
//		fclose(uop_trace);
//		fclose(z80_trace);
//	}
#endif


/*	if ((Doze.pc) == 0x0107)
	{
		Doze.pc += 0;
		FILE* test = fopen("E:\\554\\memtest_uop.txt", "w");
		for (int i=0; i<0x1fff; i++ )
			fprintf(test, "mem[%.4X]=%.2X\n", i+0x8000, pMastb->Ram[i]);
		fclose(test);
	}
*/

//	if ((Doze.pc) == 0x0417)
//		Doze.pc += 0;

/*	if ( inst_count == 0x04b86c )
		Doze.pc += 0; */


//	if ( inst_count>=0x010000 )
//	fprintf(test, "ic:%.6Xpc:%.4X,%.2X,%.4X,%.4X,%.4X,%.4X,%.4X,%.4X,%.4X,%.4X,%.4X,%.4X,%.4X\n", 
//		inst_count, Doze.pc, ((Doze.af&0xff00)>>8), Doze.bc, Doze.de, Doze.hl,
//		Doze.ix, Doze.iy, Doze.sp, Doze.af2, Doze.bc2, Doze.de2, Doze.hl2, Doze.iff);

//	inst_count++;
//	if ( inst_count == 0x1000 ) 
//	{
//		fclose(test);
//		out.close();
//	}


}
