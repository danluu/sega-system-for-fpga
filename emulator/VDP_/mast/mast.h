//---------------------------------------------------------------------------
// Mast - Master System emulator library
// Copyright (c) 2001 Dave (www.finalburn.com), all rights reserved.

// This refers to all the code except where stated otherwise
// (e.g. ym2413 emulator)

// You can use, modify and redistribute this code freely as long as you
// don't do so commercially. This copyright notice must remain with the code.
// You must state if your program uses this code.

// Dave
// Homepage: www.finalburn.com
// E-mail:  dave@finalburn.com
//---------------------------------------------------------------------------

#ifdef __cplusplus
extern "C" {
#endif

// mast.cpp
extern int dprintf (char *Format,...);
extern int MastVer; // Version number of the library

extern unsigned char MastInput[2]; // Joypads
extern unsigned int MastEx; // Extra options
#define MX_GG     (1U) // Run as Game Gear
#define MX_PAL    (2U) // Run as PAL timing
#define MX_JAPAN  (4U) // Return Japan as Region
#define MX_FMCHIP (8U) // Emulate FM chip

extern int MastDrawDo; // 1 to draw image
int MastInit();
int MastExit();
int MastSetRom(unsigned char *Rom,int RomLen);
int MastReset();
int MastHardReset();

// snd.cpp
extern int MsndRate; // sample rate of sound
extern int MsndLen;  // length in samples per frame
extern short *pMsndOut; // pointer to sound output buffer or NULL for no sound
int MsndInit();
int MsndExit();

// frame.cpp
int MastFrame();

// area.cpp
struct MastArea { void *Data; int Len; };
extern int MastAcbNull (struct MastArea *pba);
extern int (*MastAcb) (struct MastArea *pma); // Area callback
int MastAreaBattery();
int MastAreaMeka();
int MastAreaDega();

// load.cpp
int MastLoadRom(char *Name,unsigned char **pRom,int *pRomLen);

// draw.cpp
// Master system scanline
struct Mdraw
{
  unsigned short Pal[0x100]; // Palette (0000000r rrgggbbb) (0x20 used)
  unsigned char Data[0x120]; // Pixel values
  unsigned char PalChange;
  int Line; // Image line
  unsigned char ThreeD; // 0/1=normal, 2=probably 3D right image, 3=probably 3D left image
};
extern struct Mdraw Mdraw;
void MdrawCall();

// samp.cpp
extern int MastPsgEnhance;

// vgm.cpp
int VgmStart(char *VgmName);
int VgmStop(unsigned short *Gd3Text);
extern FILE *VgmFile;
extern int VgmAccurate; // 1=Sample accurate

#ifdef __cplusplus
} // End of extern "C"
#endif
