#include "app.h"

char RomFolder[256]=".";
char StateFolder[256]=".";
char VgmName[256]="";

int MenuLoadRom()
{
  char Name[256];
  OPENFILENAME Ofn; int Ret=0;

  SetCurrentDirectory(RomFolder); // Point to the rom folder

  memset(Name,0,sizeof(Name));
  memset(&Ofn,0,sizeof(Ofn));

  Ofn.lStructSize=sizeof(Ofn);
  Ofn.hwndOwner=hFrameWnd;
  Ofn.lpstrFilter="SMS/GG Roms\0*.sms;*.gg\0All Files\0*.*\0\0";
  Ofn.lpstrFile=Name;
  Ofn.nMaxFile=sizeof(Name);
  Ofn.lpstrInitialDir=".";
  Ofn.lpstrTitle="Load Rom";
  Ofn.Flags=OFN_HIDEREADONLY;
  Ofn.lpstrDefExt="sms";

  Ret=GetOpenFileName(&Ofn);

  // Get the rom folder
  memset(RomFolder,0,sizeof(RomFolder));
  GetCurrentDirectory(sizeof(RomFolder)-1,RomFolder);
  
  // Return to the application folder
  AppDirectory();

  if (Ret==0) return 1; // Cancel/error

  // Remember the Rom name
  memcpy(EmuRomName,Name,sizeof(Name));
  PostMessage(NULL,WMU_CHANGEDROM,0,0); // Post to main message loop

  return 0;
}

int MenuStatePort(int Export)
{
  char Name[256];
  OPENFILENAME Ofn; int Ret=0;

  SetCurrentDirectory(StateFolder); // Point to the state folder

  memset(Name,0,sizeof(Name));
  // Copy the name of the rom without the extension
  if (EmuTitle!=NULL) strncpy(Name,EmuTitle,sizeof(Name)-1);

  memset(&Ofn,0,sizeof(Ofn));
  Ofn.lStructSize=sizeof(Ofn);
  Ofn.hwndOwner=hFrameWnd;
  Ofn.lpstrFilter="Meka states (.s0?)\0*.s0?\0All Files (*.*)\0*.*\0\0";
  Ofn.lpstrFile=Name;
  Ofn.nMaxFile=sizeof(Name);
  Ofn.lpstrInitialDir=".";
  Ofn.Flags=OFN_HIDEREADONLY|OFN_OVERWRITEPROMPT;
  Ofn.lpstrDefExt="s00";

  if (Export)
  {
    Ofn.lpstrTitle="Export state";
    Ret=GetSaveFileName(&Ofn);
  }
  else
  {
    Ofn.lpstrTitle="Import state";
    Ret=GetOpenFileName(&Ofn);
  }

  // Get the state folder
  memset(StateFolder,0,sizeof(StateFolder));
  GetCurrentDirectory(sizeof(StateFolder)-1,StateFolder);
  
  // Return to the application folder
  AppDirectory();

  if (Ret==0) return 1; // Cancel/error

  // Remember the State name
  memcpy(StateName,Name,sizeof(Name));
  // Post to main message loop
  if (Export) PostMessage(NULL,WMU_STATEEXPORT,0,0);
  else        PostMessage(NULL,WMU_STATEIMPORT,0,0);
  return 0;
}

int MenuStateLoad(int Save)
{
  char Name[256];
  OPENFILENAME Ofn; int Ret=0;

  SetCurrentDirectory(StateFolder); // Point to the state folder

  memset(Name,0,sizeof(Name));
  // Copy the name of the rom without the extension
  if (EmuTitle!=NULL) strncpy(Name,EmuTitle,sizeof(Name)-1);

  memset(&Ofn,0,sizeof(Ofn));
  Ofn.lStructSize=sizeof(Ofn);
  Ofn.hwndOwner=hFrameWnd;
  Ofn.lpstrFilter="Dega states (.dgz)\0*.dgz\0All Files (*.*)\0*.*\0\0";
  Ofn.lpstrFile=Name;
  Ofn.nMaxFile=sizeof(Name);
  Ofn.lpstrInitialDir=".";
  Ofn.Flags=OFN_HIDEREADONLY|OFN_OVERWRITEPROMPT;
  Ofn.lpstrDefExt="dgz";

  if (Save)
  {
    Ofn.lpstrTitle="Save state";
    Ret=GetSaveFileName(&Ofn);
  }
  else
  {
    Ofn.lpstrTitle="Load state";
    Ret=GetOpenFileName(&Ofn);
  }

  // Get the state folder
  memset(StateFolder,0,sizeof(StateFolder));
  GetCurrentDirectory(sizeof(StateFolder)-1,StateFolder);
  
  // Return to the application folder
  AppDirectory();

  if (Ret==0) return 1; // Cancel/error

  // Remember the State name
  memcpy(StateName,Name,sizeof(Name));
  // Post to main message loop
  if (Save) PostMessage(NULL,WMU_STATESAVE,0,0);
  else      PostMessage(NULL,WMU_STATELOAD,0,0);
  return 0;
}

int MenuVgmStart()
{
  char Name[256];
  OPENFILENAME Ofn; int Ret=0;

  memset(Name,0,sizeof(Name));
  // Copy the name of the rom without the extension
  if (EmuTitle!=NULL) strncpy(Name,EmuTitle,sizeof(Name)-1);

  memset(&Ofn,0,sizeof(Ofn));
  Ofn.lStructSize=sizeof(Ofn);
  Ofn.hwndOwner=hFrameWnd;
  Ofn.lpstrFilter="VGM Sound Files (.vgm)\0*.vgm\0All Files (*.*)\0*.*\0\0";
  Ofn.lpstrFile=Name;
  Ofn.nMaxFile=sizeof(Name);
  Ofn.lpstrInitialDir=".";
  Ofn.Flags=OFN_HIDEREADONLY|OFN_OVERWRITEPROMPT|OFN_NOCHANGEDIR;
  Ofn.lpstrDefExt="vgm";
  Ofn.lpstrTitle="Start VGM Sound log";
  Ret=GetSaveFileName(&Ofn);

  if (Ret==0) return 1; // Cancel/error

  // Remember the State name
  memcpy(VgmName,Name,sizeof(Name));
  // Post to main message loop
  PostMessage(NULL,WMU_VGMSTART,0,0);
  return 0;
}
