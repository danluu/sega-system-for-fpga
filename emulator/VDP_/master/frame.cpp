#include "app.h"

static char *ClassName="Frame";
HWND hFrameWnd=NULL; // Frame - Window handle
HMENU hFrameMenu=NULL;
HWND hFrameStatus=NULL; // Frame - status window

// The window procedure
static LRESULT CALLBACK WindowProc(HWND hWnd,UINT Msg,WPARAM wParam,LPARAM lParam)
{
  if (Msg==WM_CREATE)
  {
    hFrameStatus=CreateStatusWindow(WS_CHILD,"",hWnd,0);
  }

  if (Msg==WM_SIZE)
  {
    RECT Rect={0,0,0,0};
    GetWindowRect(hWnd,&Rect);
    MoveWindow(hFrameStatus,Rect.left,Rect.bottom,Rect.right,Rect.bottom,1);
  }

  if (Msg==WM_PAINT) { DispPaint(); }
  if (Msg==WM_MOVE) { DispPaint(); }

  if (Msg==WM_KEYDOWN && wParam==VK_ESCAPE) { PostMessage(NULL,WMU_TOGGLEMENU,0,0); return 0; }
  if (Msg==WM_RBUTTONDOWN)                  { PostMessage(NULL,WMU_TOGGLEMENU,0,0); return 0; }

  if (Msg==WM_COMMAND)
  {
    int Item=0;
    Item=wParam&0xffff;
    if (Item==ID_FILE_LOADROM) { MenuLoadRom(); return 0; }
    if (Item==ID_FILE_FREEROM)
    {
      EmuRomName[0]=0;
      PostMessage(NULL,WMU_CHANGEDROM,0,0);
      return 0;
    }
    if (Item==ID_STATE_LOADSTATE) { MenuStateLoad(0); return 0; }
    if (Item==ID_STATE_SAVESTATE) { MenuStateLoad(1); return 0; }
    if (Item==ID_STATE_IMPORT) { MenuStatePort(0); return 0; }
    if (Item==ID_STATE_EXPORT) { MenuStatePort(1); return 0; }
    if (Item==ID_SOUND_VGMLOG_START) { MenuVgmStart(); return 0; }
    PostMessage(NULL,WMU_COMMAND,Item,0);
  }

  if (Msg==WM_CLOSE) PostQuitMessage(0);
  if (Msg==WM_DESTROY) { hFrameStatus=NULL; hFrameWnd=NULL; }

  return DefWindowProc(hWnd,Msg,wParam,lParam);
}

int FrameInit()
{
  WNDCLASSEX wc;
  ATOM Atom=0;

  // Register the window class
  memset(&wc,0,sizeof(wc));
  wc.cbSize=sizeof(wc);
  wc.style=CS_HREDRAW|CS_VREDRAW;
  wc.lpfnWndProc=WindowProc;
  wc.hInstance=hAppInst;
  wc.hIcon=LoadIcon(hAppInst,MAKEINTRESOURCE(IDI_ICON1));
  wc.hCursor=LoadCursor(NULL,MAKEINTRESOURCE(IDC_ARROW));
  wc.lpszClassName=ClassName;
  Atom=RegisterClassEx(&wc);
  if (Atom==0) return 1;

  hFrameWnd=CreateWindow(ClassName,"",WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN,
    0,0,0,0,NULL,NULL,hAppInst,NULL);
  if (hFrameWnd==NULL) return 1;

  // Load the menu from the resource
  hFrameMenu=LoadMenu(hAppInst,MAKEINTRESOURCE(IDR_MENU1));
  return 0;
}

int FrameSize()
{
  RECT WorkArea={0,0,640,480}; // Work area on the desktop
  int x=0,y=0,w=0,h=0;
  if (hFrameWnd==NULL) return 1;

  // Get the desktop work area
  SystemParametersInfo(SPI_GETWORKAREA,0,&WorkArea,0);
  // Find midpoint
  x=WorkArea.left  +WorkArea.right; x>>=1;
  y=WorkArea.bottom+WorkArea.top;   y>>=1;

  w=WorkArea.right -WorkArea.left;
  h=WorkArea.bottom-WorkArea.top;

  w=w*3/4; h=h*3/4;

  x-=w>>1;
  y-=h>>1;

  MoveWindow(hFrameWnd,x,y,w,h,1);
  return 0;
}

int FrameExit()
{
  SetMenu(hFrameWnd,NULL);
  if (hFrameMenu!=NULL) DestroyMenu(hFrameMenu);  hFrameMenu=NULL;

  // Destroy window if not already destroyed
  if (hFrameWnd!=NULL) DestroyWindow(hFrameWnd);  hFrameWnd=NULL;

  // Unregister the window class
  UnregisterClass(ClassName,hAppInst);
  return 0;
}
