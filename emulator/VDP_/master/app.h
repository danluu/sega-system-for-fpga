#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <commdlg.h>
#pragma warning (push)
#pragma warning (disable:4201)
#include <mmsystem.h>
#pragma warning (pop) 
#define DIRECTDRAW_VERSION 0x0300
#include <ddraw.h>
#define DIRECTINPUT_VERSION 0x0500
#include <dinput.h>

#include "../mast/mast.h"
#include "resource.h"

// Make the INLINE macro
#undef INLINE
#define INLINE inline

#define APP_TITLE "Dega"

// main.cpp
extern HINSTANCE hAppInst;
extern int ScrnWidth,ScrnHeight;
extern int Fullscreen;
extern HACCEL hAccel; // Key accelerators

// loop.cpp
extern int AppShowCmd;
extern int SetupPal;
int LoopDo();

// misc.cpp
char *UnwrapString(char *Source,int StopAtSpace);
char *GetFilename(char *Full);
int AppError(char *Text,int bWarning);
int AppDirectory();
char *GetStubName(char *Full);
int GetClientScreenRect(HWND hWnd,RECT *pRect);
int IntegerScale(RECT *pRect,int FitWidth,int FitHeight);
char *AppName();
int GetSurfaceFormat(IDirectDrawSurface *pSurf,unsigned int *pFormat,int *pBpp);
int AutodetectUseSys(IDirectDraw *pDirDraw);
int SurfaceClear(IDirectDrawSurface *Surf,unsigned int Col);

// run.cpp
int RunFrame(int Draw,short *pSound);
int RunStart();
int RunStop();
int RunText(char *Text,int Len);

// emu.cpp
extern char EmuRomName[];
extern char *EmuTitle;
int EmuInit();
int EmuExit();
int EmuLoad();
int EmuFree();
int EmuFrame();

// dsound.cpp
extern int DSoundSamRate;     // sample rate
extern int DSoundSegCount;    // Segs in the pdsbLoop buffer
extern int FramesPerSecond;    // Application fps
extern int DSoundSegLen;      // Seg length in samples (calculated from Rate/Fps)
extern short *DSoundNextSound; // The next sound seg we will add to the sample loop
extern unsigned char DSoundPlaying;  // True if the Loop buffer is playing
extern int (*DSoundGetNextSound) (int Draw); // Callback used to request more sound
int DSoundCheck();
int DSoundInit(HWND hWnd);
int DSoundPlay();
int DSoundStop();
int DSoundExit();

// frame.cpp
extern HWND hFrameWnd; // Frame - Window handle
extern HMENU hFrameMenu;
int FrameInit();
int FrameExit();
int FrameSize();
extern HWND hFrameStatus; // Frame - status window

// input.cpp
extern int UseJoystick;
int InputGet();

// disp.cpp
extern IDirectDraw *pDD;
extern IDirectDrawSurface *DispPrim,*DispBuff,*DispOver;
extern unsigned char *DispMem;
extern int DispMemPitch;
extern unsigned int DispFormat; // Either a FourCC code or a color depth
extern int DispBpp; // Bytes per pixel
extern int TryOverlay;
int DispInit();
int DispExit();
int DispPaint();
int DispDraw();

// render.cpp
extern int RedBlue3D;
int RenderInit();

// dinp.cpp
int DirInputInit(HINSTANCE hInst,HWND hPassWnd);
int DirInputExit();
int DirInputStart();
int DirInputState(int Code);
int DirInputFind();

// load.cpp
extern char RomFolder[];
extern char StateFolder[];
extern char VgmName[];
int MenuLoadRom();
int MenuStatePort(int Export);
int MenuStateLoad(int Save);
int MenuVgmStart();
#define WMU_TOGGLEMENU  (WM_APP+0)
#define WMU_CHANGEDROM  (WM_APP+1)
#define WMU_COMMAND     (WM_APP+2)
#define WMU_STATELOAD   (WM_APP+3)
#define WMU_STATESAVE   (WM_APP+4)
#define WMU_STATEIMPORT (WM_APP+5)
#define WMU_STATEEXPORT (WM_APP+6)
#define WMU_VGMSTART    (WM_APP+7)

// conf.cpp
int ConfLoad();
int ConfSave();

// state.cpp
extern char StateName[];
extern int AutoLoadSave;
int StateLoad(int Meka);
int StateSave(int Meka);
int StateAuto(int Save);

// shot.cpp
int ShotStart();
void ShotLine();
int ShotExit();
int ShotSave();

