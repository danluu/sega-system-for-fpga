// Loop module
#include "app.h"

static int ShowMenu=1;
int SetupPal=0;
static int LoopPause=0;
static MSG Msg;

// Reinit the media, going down to a certain level
static int MediaInit(int Level)
{
  int Ret=0; char WinName[128]="";

  if (Level<=10) // Frame and DirectInput
  {
    Ret=FrameInit(); if (Ret!=0) { AppError("FrameInit Failed",0); return 1; }
    FrameSize();
    ShowWindow(hFrameWnd,SW_SHOWDEFAULT);
    DirInputInit(hAppInst,hFrameWnd); // not critical if it fails
  }

  if (Level<=15) // Mast library
  {
    Ret=EmuInit(); if (Ret!=0) { AppError("EmuInit Failed",0); return 1; }
  }

  if (Level<=20) // Game load
  {
    unsigned int Enabled=MF_GRAYED;
    Ret=EmuLoad();
    if (Ret==0) { ShowMenu=0; Enabled=MF_ENABLED; LoopPause=0; }
    EnableMenuItem(hFrameMenu,ID_FILE_RESET  ,Enabled);
    EnableMenuItem(hFrameMenu,ID_FILE_FREEROM,Enabled);

    StateAuto(0); // Auto load the state
    // Size and show the frame window

    // Make frame window title
    if (EmuTitle!=NULL)
    {
      sprintf (WinName,"%.60s.%s - %s",EmuTitle,(MastEx&MX_GG) ? "gg":"sms",AppName());
    }
    else
    { sprintf (WinName,"%s",AppName()); }

    SetWindowText(hFrameWnd,WinName);

    if (MastEx&MX_GG) { ScrnWidth=160; ScrnHeight=144; } // Game gear
    else              { ScrnWidth=256; ScrnHeight=192; } // Master System

  }

  if (Level<=30) // DirectDraw
  {
    Ret=DispInit(); if (Ret!=0) { AppError("DispInit Failed",0); return 1; }
    // Repaint the Frame Window
    InvalidateRect(hFrameWnd,NULL,1);
    UpdateWindow(hFrameWnd);
  }

  if (Level<=35) // Window size
  {
    if (Msg.wParam==ID_SETUP_FULLSCREEN)
    {
      if (Fullscreen)
      {
        SetWindowLong(hFrameWnd,GWL_STYLE,WS_POPUP|WS_CLIPCHILDREN);
        ShowWindow(hFrameWnd,SW_MAXIMIZE);
      }
      else
      {
        ShowWindow(hFrameWnd,SW_HIDE);
        SetWindowLong(hFrameWnd,GWL_STYLE,WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN);
        FrameSize();
        ShowWindow(hFrameWnd,SW_NORMAL);
      }
    }
  }

  if (Level<=50) // Sound
  {
    if (SetupPal==0 || MastEx&MX_GG) { MastEx&=~MX_PAL; FramesPerSecond=60; } 
    else                             { MastEx|= MX_PAL; FramesPerSecond=50; }
  
    DSoundInit(hFrameWnd);
  }

  if (Level<=55) // Emu Sound
  {
    MsndRate=DSoundSamRate; MsndLen=DSoundSegLen;
    MsndInit();
  }

  if (Level<=60) // Run thread
  {
    ShotExit(); // Get rid of previous screenshots

    // Make sure we have a screenshot image in situations where the image isn't in motion
    // (this is done so that the user takes a screenshot of the paused frame)
    if (Msg.wParam==ID_SETUP_ONEFRAME || Msg.wParam==ID_SETUP_PAUSE)
    {
      if (LoopPause) { ShotStart(); RunFrame(1,NULL); }
    }

    // Start the Run thread
    if (LoopPause==0)
    {
      RunStart();
      DSoundPlay();
    }
  }

  if (Level<=70) // Menu
  {
   
#define CHK(a,b) CheckMenuItem(hFrameMenu,a,(b)?MF_CHECKED:MF_UNCHECKED);

    CHK(ID_SETUP_PAL,SetupPal)
    // Disable the NTSC/PAL switch if it's the game gear
    EnableMenuItem(hFrameMenu,ID_SETUP_PAL ,MastEx&MX_GG ? MF_GRAYED : MF_ENABLED);

    CHK(ID_SETUP_JAPAN,MastEx&MX_JAPAN)
    CHK(ID_SETUP_FMCHIP,MastEx&MX_FMCHIP)
    CHK(ID_SETUP_OVERLAY_NONE,TryOverlay==0)
    CHK(ID_SETUP_OVERLAY_YUV, TryOverlay==1)
    CHK(ID_SETUP_OVERLAY_RGB, TryOverlay==2)
    CHK(ID_SETUP_FULLSCREEN, Fullscreen)
    CHK(ID_SETUP_REDBLUE3D, RedBlue3D)
    CHK(ID_SETUP_PAUSE, LoopPause)
    CHK(ID_INPUT_KEYBOARD,UseJoystick==0)
    CHK(ID_INPUT_JOYSTICK,UseJoystick!=0)
    CHK(ID_STATE_AUTOLOADSAVE,AutoLoadSave!=0)
    CHK(ID_SOUND_ENHANCEPSG,MastPsgEnhance)
    CHK(ID_SOUND_QUALITY_OFF,DSoundSamRate==0)
    CHK(ID_SOUND_QUALITY_12000HZ,DSoundSamRate==12000)
    CHK(ID_SOUND_QUALITY_44100HZ,DSoundSamRate==44100)
    EnableMenuItem(hFrameMenu,ID_SOUND_VGMLOG_START,VgmFile==NULL ? MF_ENABLED : MF_GRAYED);
    EnableMenuItem(hFrameMenu,ID_SOUND_VGMLOG_STOP, VgmFile!=NULL ? MF_ENABLED : MF_GRAYED);
    CHK(ID_SOUND_VGMLOG_SAMPLEACCURATE,VgmAccurate)

    if (ShowMenu) SetMenu(hFrameWnd,hFrameMenu);
    else          SetMenu(hFrameWnd,NULL);

    if (Fullscreen && ShowMenu==0) { while (ShowCursor(0)>=0) ; } // Hide mouse
  }
  return 0;
}

// Exit the media, going down to a certain level
static int MediaExit(int Level)
{
  if (Level<=70)
  {
    while (ShowCursor(1)< 0) ; // Show mouse
  }

  if (Level<=60)
  {
    DSoundStop();
    RunStop();
  }

  if (Level<=55)
  {
    MsndExit();
    MsndLen=0; MsndRate=0;
  }

  if (Level<=50)
  {
    DSoundStop();
    DSoundExit();
    MastEx&=~MX_PAL;
  }

  if (Level<=30)
  {
    DispExit();
  }
 
  if (Level<=20)
  {
    StateAuto(1); // Auto save the state
    EmuFree();
  }

  if (Level<=15)
  {
    VgmStop(NULL);
    EmuExit();
  }

  if (Level<=10)
  {
    DirInputExit();
    FrameExit();
  }

  if (Level<=0)
  {
    ShotExit(); // Deallocate screenshot
  }
  return 0;
}


// Main program loop
int LoopDo()
{
  int Ret=0; int InitLevel=10;
  memset(&Msg,0,sizeof(Msg));

  for (;;)
  {
    // Perform any changes which are needed
    if (Msg.message==WMU_COMMAND)
    {
      if (Msg.wParam==ID_FILE_RESET) MastReset();

      if (Msg.wParam==ID_SETUP_PAL) SetupPal=!SetupPal;
      if (Msg.wParam==ID_SETUP_JAPAN) MastEx^=MX_JAPAN;
      if (Msg.wParam==ID_SETUP_FMCHIP) MastEx^=MX_FMCHIP;
      if (Msg.wParam==ID_SETUP_OVERLAY_NONE) TryOverlay=0;
      if (Msg.wParam==ID_SETUP_OVERLAY_YUV)  TryOverlay=1;
      if (Msg.wParam==ID_SETUP_OVERLAY_RGB)  TryOverlay=2;
      if (Msg.wParam==ID_SETUP_FULLSCREEN)
      {
        Fullscreen=!Fullscreen;
        if (Fullscreen) ShowMenu=0;
      }
      if (Msg.wParam==ID_SETUP_REDBLUE3D) RedBlue3D=!RedBlue3D;
      if (Msg.wParam==ID_OPTIONS_SCREENSHOT)
      {
        if (LoopPause==0) { ShotStart(); RunFrame(1,NULL); }
        ShotSave();
      }

      if (Msg.wParam==ID_SETUP_PAUSE)
      {
        LoopPause=!LoopPause;
        if (LoopPause) RunText("Emulator Paused",2*60);
        else           RunText("Emulator Unpaused",2*60);
      }

      if (Msg.wParam==ID_SETUP_ONEFRAME)
      {
        RunText("One Frame Step",2*60);
        RunFrame(1,NULL);
      }
      
      if (Msg.wParam==ID_INPUT_KEYBOARD) UseJoystick=0;
      if (Msg.wParam==ID_INPUT_JOYSTICK) UseJoystick=1;
      if (Msg.wParam==ID_STATE_AUTOLOADSAVE) AutoLoadSave=!AutoLoadSave;
      if (Msg.wParam==ID_SOUND_ENHANCEPSG) MastPsgEnhance=!MastPsgEnhance;
      if (Msg.wParam==ID_SOUND_QUALITY_OFF) DSoundSamRate=0;
      if (Msg.wParam==ID_SOUND_QUALITY_12000HZ) DSoundSamRate=12000;
      if (Msg.wParam==ID_SOUND_QUALITY_44100HZ) DSoundSamRate=44100;
      if (Msg.wParam==ID_SOUND_VGMLOG_STOP) { VgmStop(NULL); }
      if (Msg.wParam==ID_SOUND_VGMLOG_SAMPLEACCURATE) { VgmAccurate=!VgmAccurate; }
    }
    if (Msg.message==WMU_STATELOAD)   { StateLoad(0); }
    if (Msg.message==WMU_STATESAVE)   { StateSave(0); }
    if (Msg.message==WMU_STATEIMPORT) { StateLoad(1); }
    if (Msg.message==WMU_STATEEXPORT) { StateSave(1); }
    if (Msg.message==WMU_VGMSTART) { VgmStart(VgmName); }

    Ret=MediaInit(InitLevel); if (Ret!=0) { InitLevel=0; goto Error; }

    for (;;)
    {
      int Ret=0;

      InitLevel=80;
      Ret=GetMessage(&Msg,NULL,0,0);

      // Check for changes which mean we need to re-init down to a certain level
      if (Msg.message==WMU_TOGGLEMENU) { ShowMenu=!ShowMenu; InitLevel=70; break; }
      if (Msg.message==WMU_CHANGEDROM) {                     InitLevel=20; break; }
      if (Msg.message==WM_QUIT)        {                     InitLevel=0 ; break; }
      if (Msg.message==WMU_COMMAND)
      {
        if (Msg.wParam==ID_FILE_RESET)         { InitLevel=60; break; }
        if (Msg.wParam==ID_FILE_EXIT)          { InitLevel=0 ; break; }
        if (Msg.wParam==ID_SETUP_PAL)          { InitLevel=50; break; }
        if (Msg.wParam==ID_SETUP_JAPAN)        { InitLevel=70; break; }
        if (Msg.wParam==ID_SETUP_FMCHIP)       { InitLevel=70; break; }
        if (Msg.wParam==ID_SETUP_OVERLAY_NONE) { InitLevel=30; break; }
        if (Msg.wParam==ID_SETUP_OVERLAY_YUV)  { InitLevel=30; break; }
        if (Msg.wParam==ID_SETUP_OVERLAY_RGB)  { InitLevel=30; break; }
        if (Msg.wParam==ID_SETUP_FULLSCREEN)   { InitLevel=35; break; }
        if (Msg.wParam==ID_SETUP_REDBLUE3D)    { InitLevel=70; break; }
        if (Msg.wParam==ID_SETUP_PAUSE)        { InitLevel=60; break; }
        if (Msg.wParam==ID_SETUP_ONEFRAME)     { InitLevel=60; break; }
        if (Msg.wParam==ID_OPTIONS_SCREENSHOT) { InitLevel=60; break; }
        if (Msg.wParam==ID_INPUT_KEYBOARD)     { InitLevel=60; break; }
        if (Msg.wParam==ID_INPUT_JOYSTICK)     { InitLevel=60; break; }
        if (Msg.wParam==ID_STATE_AUTOLOADSAVE) { InitLevel=70; break; }
        if (Msg.wParam==ID_SOUND_ENHANCEPSG)   { InitLevel=50; break; }
        if (Msg.wParam==ID_SOUND_QUALITY_OFF)     { InitLevel=50; break; }
        if (Msg.wParam==ID_SOUND_QUALITY_12000HZ) { InitLevel=50; break; }
        if (Msg.wParam==ID_SOUND_QUALITY_44100HZ) { InitLevel=50; break; }
        if (Msg.wParam==ID_SOUND_VGMLOG_STOP)  { InitLevel=60; break; }
        if (Msg.wParam==ID_SOUND_VGMLOG_SAMPLEACCURATE) { InitLevel=60; break; }
      }
      if (Msg.message==WMU_STATELOAD) { InitLevel=60; break; }
      if (Msg.message==WMU_STATESAVE) { InitLevel=60; break; }
      if (Msg.message==WMU_STATEIMPORT) { InitLevel=60; break; }
      if (Msg.message==WMU_STATEEXPORT) { InitLevel=60; break; }
      if (Msg.message==WMU_VGMSTART)    { InitLevel=60; break; }

      if (hAccel!=NULL) TranslateAccelerator(hFrameWnd,hAccel,&Msg);
      TranslateMessage(&Msg);
      DispatchMessage(&Msg);
    }

  Error:
    // Exit everything
    MediaExit(InitLevel);

    if (InitLevel<=0) break; // Quit program
  }
  return 0;
}
