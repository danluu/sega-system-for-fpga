// Mast - internal code

// Standard headers
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mast.h"

// Do everything as extern "C" to simplify linking
extern "C" {

// Make the INLINE macro
#undef INLINE
#define INLINE inline
#pragma warning (disable:4514) //disable "unreferenced inline function removed" warning message
#pragma warning (disable:4710) //disable "function not inlined" warning message

// Chip emulators ------------------------------------------------
#define EMU_DOZE // Use my 'Doze' Assembler Z80 emulator

// Include cpu emu headers
#ifdef EMU_DOZE
#include "doze.h"
#endif

// Include sound emu header
extern "C"
{
#include "emu2413.h"
}

// video chip
struct Mastv
{
  unsigned short Low;   // Low byte of video command
  unsigned char  Wait;  // 1 if waiting for the high byte at port bf
  unsigned char  Stat;  // Status
  unsigned char  Reg[0x10]; // Video registers
  unsigned char  Mode;  // Video read/write mode
  unsigned short Addr;  // Video read/write addr
};

// dpsg.cpp
struct Dpsg
{
  unsigned char  Volume[4]; // Volume 0-15
  unsigned short Period[4]; // Period 0-0x3ff
  unsigned char  Stereo; // Stereo info
  unsigned char  Last; // Last byte sent
};

extern int DpsgRate;
int DpsgInit();
int DpsgRecalc();
void DpsgWrite(unsigned char d);
void DpsgStereo(unsigned char d);
void DpsgCalc(int *Total);

// z) Parts of the Mast state which are calculated
struct Mastz
{
  unsigned char *Rom; int RomLen;
  int RomPage[3]; // Offsets to Rom banks
};

// a) Parts of the Mast state which are loaded
struct Masta
{
  unsigned char Bank[4];  // Values written to fffc-f
  struct Mastv v; // video chip
  struct Dpsg p; // PSG chip
  unsigned char Irq; // 1 if an IRQ is latched
};

// b) Parts of the Mast state which are pointed to
struct Mastb
{
  // (NB - order used by MastAreaDega)
  unsigned char Sram[0x4000]; // battery backup ram
  unsigned char Ram [0x2000]; // normal ram
  unsigned char VRam[0x4000]; // video ram
  unsigned char CRam[0x0040]; // color ram
  unsigned char Out3F; // Value written to port 3f
  unsigned char ThreeD; // Value written to fffb (3D glasses toggle)
  unsigned char FmSel; // Selected FM register
  unsigned char FmDetect; // Value written to port f2
  unsigned char FmReg[0x40]; // Current FM values
};

// mast.cpp
extern struct Mastz Mastz;
extern struct Masta Masta;
extern struct Mastb *pMastb;
int MastsSetRom(unsigned char *Rom,int RomLen);

// snd.cpp
extern int MsndDone; // Sound rendered so far this frame
extern OPLL *MastOpl;
void MsndStart();
void MsndTo(int To);
int MsndRefresh();
void MsndFm(unsigned char a,unsigned char d);

// frame.cpp
extern int MastY; // 0-261
int CpuMid(); // Returns how many cycles the z80 has done inside the run call
void MastSoundUpdate();

// map.cpp
int MastMapMemory();
void MastMapPage0();
void MastMapPage1();
void MastMapPage2();

// draw.cpp
int MdrawInit();
void MdrawCramChange(int a);
void MdrawCramChangeAll();
void MdrawDo();

// samp.cpp
struct Sample
{
  unsigned char *Data;
  int Len; int PeriodCount;
  int LoopDist;
};
extern struct Sample Sample[];
int SampInit();
int SampExit();

// vgm.cpp
int VgmCycleDone(int n);
void VgmPsg(unsigned char d);
void VgmPsgStereo(unsigned char d);
void VgmFm(unsigned char a,unsigned char d);

} // End of extern "C"
