/*==========================================================================================*
|	Z80 instruction decoding and processing for emualtor									|
|																							|
|						Writen by SMS-IO Group (Tsung-Hao, Chen ; Tsung-Chi, Lin)			|
| ----------------------------------------------------------------------------------------- |
|	Date:																					|
|	10/30/2002	Original version established.												|
|	10/31/2002	Convert decode procedure from verilog codes of pre_decoder created by kim	|
|	11/01/2002	Establish z80_I_run function												|
*==========================================================================================*/


#include "dozeint_554.h"
#include "DataValue.h"
#include "z80_I_ID.h"		// include instruction ID definitions
#include "z80_I_run.h"
#include "z80_decoder.h"

#include "micro_inst.h"
#include "z80_uOP_run.h"

Flag flag;
BUS bus_pre;
unsigned char _ID;

void DozeAsmRun_chi()
{
	//extern nDozeCycles
	unsigned char inst1;
	unsigned char inst2;
	unsigned char inst3;
	unsigned char inst4;

#ifdef ORIG_Z80
////////////////// Z80_style /////////////////////////////////////////////
	while ( nDozeCycles >0 )
	{
		inst1 = DozeAsmRead(Doze.pc++);
		#include "Z80_1byte_inst.h"			
		inst2 = DozeAsmRead(Doze.pc++);
		#include "Z80_2byte_inst.h"
		inst3 = DozeAsmRead(Doze.pc++);
		#include "Z80_3byte_inst.h"
		inst4 = DozeAsmRead(Doze.pc++);
		#include "Z80_4byte_inst.h"

	end_inst:
		if (nDozeEi == 2) return;
	}
////////////////// Micro_ISA_style /////////////////////////////////////////
#else

	while ( nDozeCycles >0 )
	{							// PC value take care in Micro-OPs
		inst1 = DozeAsmRead(Doze.pc++);
		#include "RISC_Z80_1byte_inst.h"			
		inst2 = DozeAsmRead(Doze.pc++);
		#include "RISC_Z80_2byte_inst.h"
		inst3 = DozeAsmRead(Doze.pc++);
		#include "RISC_Z80_3byte_inst.h"
		inst4 = DozeAsmRead(Doze.pc++);
		#include "RISC_Z80_4byte_inst.h"

	end_micro_inst:
		if (nDozeEi == 2) return;
	}
#endif 

}
