//---------------------------------------------------------------------------
// Doze - Dave's optimized Z80 emulator
// Copyright (c) 2001 Dave (www.finalburn.com), all rights reserved.

// You can use, modify and redistribute this code freely as long as you
// don't do so commercially. This copyright notice must remain with the code.
// You must state if your program uses this code.

// Dave
// Homepage: www.finalburn.com
// E-mail:  dave@finalburn.com
// -------------------------------------------------------------------------------------------

// Change log
// 1.001 : Fixed mistake in timing of ini/r/d/outi/r/d  (4+16 cycles should have
//         been 4+12 cycles)

// (external) Header

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __DOZE_H
#define __DOZE_H

// Application defined:
unsigned char __cdecl DozeRead(unsigned short a);
void __cdecl DozeWrite(unsigned short a, unsigned char d);
unsigned char __cdecl DozeIn(unsigned short a);
void __cdecl DozeOut(unsigned short a, unsigned char d);

// dozea.asm
struct DozeReg
{
  unsigned short af ,bc ,de ,hl ,ix,iy,pc,sp, o_pc;
  unsigned short af2,bc2,de2,hl2,ir;
  unsigned short iff; // iff.h = IFF2    iff.l = IFF1
  unsigned char im;
};

extern struct DozeReg Doze;
extern int nDozeCycles;
// Memory access:
extern unsigned int DozeMemFetch[0x100];
extern unsigned int DozeMemRead [0x100];
extern unsigned int DozeMemWrite[0x100];
unsigned char __cdecl DozeAsmRead(unsigned short nAddr);

// doze.cpp
extern int nDozeVer; // Version number of the library
extern int nDozeInterrupt; // Interrupt latch
int __cdecl DozeNmi();
void __cdecl DozeRun();
int __cdecl DozeReset();

#endif

#ifdef __cplusplus
} // End of extern "C"
#endif
