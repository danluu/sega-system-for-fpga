// Misc functions module
#include "app.h"

// Show a message box with an error message
int AppError(char *Text,int bWarning)
{
  MessageBox(hFrameWnd,Text,
    bWarning ? APP_TITLE " Warning" :  APP_TITLE " Error",
    MB_OK | (bWarning?MB_ICONWARNING:MB_ICONERROR)
  );
  return 0;
}

// Unwraps a string of the form "\path a\path b\program.exe" or \patha\pathb\program.exe
char *UnwrapString(char *Source,int StopAtSpace)
{
  char *pStart=NULL,*pc=NULL,*Copy=NULL; int Len=0;

  if (Source==NULL) return NULL;
  if (Source[0]=='\"')
  {
    // Quoted string
    pStart=Source+1; // Set the start
    for (pc=pStart; *pc; pc++) { if (*pc=='\"') break; } // Find the last quote or \0
    Len=pc-pStart; // Calc the length
  }
  else
  {
    // Unquoted string
    pStart=Source; // Set the start
    for (pc=pStart; *pc; pc++) { if (StopAtSpace && *pc==' ') break; } // Find a space or \0
    Len=pc-pStart; // Calc the length
  }

  Copy=(char *)malloc(Len+1); if (Copy==NULL) return NULL;
  memcpy(Copy,pStart,Len); Copy[Len]=0; // Copy string and zero-terminate
  return Copy; // Return the copy
}

char *GetFilename(char *Full)
{
  int i,Len;
  Len=strlen(Full); if (Len<=0) return Full;
  for (i=Len-1;i>=0;i--) if (Full[i]=='\\' || Full[i]=='/') return Full+i+1;
  return Full;
}

char *GetStubName(char *Full)
{
  int i=0,Len=0; char *NewMem=NULL;
  
  Len=strlen(Full); if (Len<=0) return NULL;
  // Reduce the length to before a dot
  for (i=Len-1;i>=0;i--)
  {
    if (Full[i]=='.') { Len=i; break; }
  }

  // Reduce the length after a slash
  for (i=Len-1;i>=0;i--)
  {
    if (Full[i]=='\\') { Full+=i+1; Len-=i+1; break; }
  }

  // Copy that section of the string
  NewMem=(char *)malloc(Len+1); if (NewMem==NULL) return NULL;
  memcpy(NewMem,Full,Len);
  NewMem[Len]=0;

  return NewMem;
}

// Set the current directory to be the application's directory
int AppDirectory()
{
  char *Cmd=NULL,*Prog=NULL,*pc=NULL;

  Cmd=GetCommandLine();
  Prog=UnwrapString(Cmd,1);
  if (Prog==NULL) return 1;

  for (pc=Prog; *pc; pc++) { }; // Find the end of the string
  // Find the last \ or /
  for ( ; pc>=Prog; pc--)
  {
    if (*pc=='\\') break;
    if (*pc=='/') break;
  }

  *pc=0; // Change to zero-terminate

  // Finally set the current directory to be the application's directory
  SetCurrentDirectory(Prog);
  free(Prog);
  return 0;
}

// Get the position of the client area of a window on the screen
int GetClientScreenRect(HWND hWnd,RECT *pRect)
{
  POINT Corner={0,0};
  GetClientRect(hWnd,pRect);
  ClientToScreen(hWnd,&Corner);
  pRect->left+=Corner.x; pRect->right+=Corner.x;
  pRect->top+=Corner.y; pRect->bottom+=Corner.y;
  return 0;
}

// This function takes a rectangle and scales it to a multiple of the
// screen resolution, so that the video hardware doesn't have to do a fractional scale
// (which looks bad in DirectDraw).
int IntegerScale(RECT *pRect,int FitWidth,int FitHeight)
{
  int xm,ym; // The multiple of FitWidth and FitHeight we can fit in
  int m; // The multiple of both we can fit in
  int Width,Height;
  Width =pRect->right-pRect->left;
  Height=pRect->bottom-pRect->top;

  xm=Width/FitWidth; ym=Height/FitHeight;
  m=xm; if (m>ym) m=ym;
  if (m>=1)
  {
    Width=FitWidth*m;
    Height=FitHeight*m;
  }

  pRect->left=(pRect->right+pRect->left)/2;
  pRect->left-=Width/2;
  pRect->right=pRect->left+Width;

  pRect->top=(pRect->top+pRect->bottom)/2;
  pRect->top-=Height/2;
  pRect->bottom=pRect->top+Height;
  return 0;
}

// Return the application name with versions number
char *AppName()
{
  static char Name[64];
  if (MastVer&0xf) sprintf (Name,APP_TITLE " v%x.%.3x",MastVer>>12,MastVer&0xfff);
  else             sprintf (Name,APP_TITLE " v%x.%.2x",MastVer>>12,(MastVer>>4)&0xff);
  return Name;
}

int GetSurfaceFormat(IDirectDrawSurface *pSurf,unsigned int *pFormat,int *pBpp)
{
  int Depth=0; int Ret=0;
  DDPIXELFORMAT ddpf;
  *pFormat=8; *pBpp=1;

  if (pSurf==NULL) return 1;

  // Find out the pixelformat of the screen surface
  memset(&ddpf,0,sizeof(ddpf));
  ddpf.dwSize=sizeof(ddpf);
  Ret=pSurf->GetPixelFormat(&ddpf);
  if (Ret<0) return 1;
  
  if (ddpf.dwFlags&DDPF_FOURCC)
  {
    if (ddpf.dwFourCC==MAKEFOURCC('U','Y','V','Y'))
    { *pFormat=ddpf.dwFourCC; *pBpp=2; return 0; }

    if (ddpf.dwFourCC==MAKEFOURCC('Y','U','Y','2'))
    { *pFormat=ddpf.dwFourCC; *pBpp=2; return 0; }

    return 1;
  }

  Depth=ddpf.dwRGBBitCount;
  if (Depth==16 && ddpf.dwGBitMask==0x03e0) Depth=15;

  *pFormat=Depth; *pBpp=(Depth+7)>>3;
  return 0;
}

int AutodetectUseSys(IDirectDraw *pDirDraw)
{
  // Try to autodetect the best secondary buffer type to use, based on the cards capabilities
  DDCAPS ddc;
  if (pDirDraw==NULL) return 1;
  memset(&ddc,0,sizeof(ddc)); ddc.dwSize=sizeof(ddc); pDirDraw->GetCaps(&ddc,NULL);

  // If it can do a hardware stretch use video memory
  if (ddc.dwCaps&DDCAPS_BLTSTRETCH) return 0;
  // Otherwise use system memory:
  return 1;
}

int SurfaceClear(IDirectDrawSurface *Surf,unsigned int Col)
{
  // Clear a surface to black
  int Ret=0;  DDBLTFX BltFx;
  if (Surf==NULL) return 1;
  memset(&BltFx,0,sizeof(BltFx));
  BltFx.dwSize=sizeof(BltFx);
  BltFx.dwFillColor=Col;
  Ret=Surf->Blt(NULL,NULL,NULL,DDBLT_COLORFILL,&BltFx);
  if (Ret<1) return 1;
  return 0;
}

