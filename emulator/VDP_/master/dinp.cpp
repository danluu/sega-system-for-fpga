// Input module
#include "app.h"

static IDirectInput *pDI=NULL; // DirectInput interface
static HWND hWnd=NULL; // The window handle to use for DirectInput

#define MAX_JOYSTICKS (64)
static IDirectInputDevice2 *JoyList[MAX_JOYSTICKS]={NULL};
// Number of joysticks connected to this machine
static int JoystickCount=0;

static DIJOYSTATE *pCalcState=NULL;
#define DINPUT_BUTTON_COUNT (sizeof(pCalcState->rgbButtons)/sizeof(pCalcState->rgbButtons[0]))

// This function is called back with each joystick connected to the system
static BOOL CALLBACK DIEnumDevicesProc(LPCDIDEVICEINSTANCE pDDI,LPVOID pvRef)
{
  int Ret=0;
  IDirectInputDevice *pDev=NULL;
  IDirectInputDevice2 *pDev2=NULL;
  (void)pvRef;

  if (pDDI==NULL) goto End;

  // create the DirectInput joystick device 
  Ret=pDI->CreateDevice(pDDI->guidInstance,&pDev,NULL);
  if (Ret<0 || pDev==NULL) goto End;

  // Get the DirectInputDevice2 interface so we can use the Poll method
  Ret=pDev->QueryInterface(IID_IDirectInputDevice2,(void **)&pDev2);
  pDev->Release(); pDev=NULL;
  if (Ret<0 || pDev2==NULL) goto End;

  // We now have a IDirectInputDevice2 interface to store
  if (JoystickCount<MAX_JOYSTICKS) JoyList[JoystickCount++]=pDev2;

End:
  return DIENUM_CONTINUE;
}

// Sets up one Joystick (for example the range of the joystick's axes)
static int SetUpJoystick(IDirectInputDevice2 *pJoy)
{
  int Ret=0;
  DIPROPRANGE diprg={0}; 
  if (pJoy==NULL) return 1;

  Ret=pJoy->SetDataFormat(&c_dfDIJoystick);
  if (Ret!=DD_OK) return 1;
  Ret=pJoy->SetCooperativeLevel(hWnd,DISCL_NONEXCLUSIVE|DISCL_BACKGROUND);

  // Ensure range is 0x00000 to 0x10000 (the default)
  memset(&diprg,0,sizeof(diprg));
  diprg.diph.dwSize       = sizeof(diprg);
  diprg.diph.dwHeaderSize = sizeof(diprg.diph);
  diprg.diph.dwObj        = DIJOFS_X;
  diprg.diph.dwHow        = DIPH_BYOFFSET;
  diprg.lMin              = 0x00000;
  diprg.lMax              = 0x10000;
  Ret=pJoy->SetProperty(DIPROP_RANGE,&diprg.diph);
  diprg.diph.dwObj        = DIJOFS_Y;
  Ret=pJoy->SetProperty(DIPROP_RANGE,&diprg.diph);
  
  Ret=pJoy->Acquire();

  return 0;
}

// Sets up all the joysticks
static int SetUpJoysticks()
{
  int i=0; for (i=0;i<JoystickCount;i++) SetUpJoystick(JoyList[i]);
  return 0;
}

int DirInputInit(HINSTANCE hInst,HWND hPassWnd)
{
  int Ret=0;
  hWnd=hPassWnd;
  // Make sure all DI2 joystick references are NULL
  JoystickCount=0;
  memset(&JoyList,0,sizeof(JoyList));

  Ret=DirectInputCreate(hInst,DIRECTINPUT_VERSION,&pDI,NULL);
  if (Ret<0) return 1;

  // enumerate the joysticks connected to the system
  Ret=pDI->EnumDevices(DIDEVTYPE_JOYSTICK,DIEnumDevicesProc,NULL,DIEDFL_ATTACHEDONLY);
  if (Ret<0) return 1;

  // Set up the DI2 devices
  SetUpJoysticks();

  return 0;
}

int DirInputExit()
{
  int i=0;
  // Release all the DI2 interfaces
  for (i=0;i<MAX_JOYSTICKS;i++) { if (JoyList[i]!=NULL) JoyList[i]->Release();  JoyList[i]=NULL; }
  JoystickCount=0;

  // Release the DirectInput interface
  if (pDI!=NULL) pDI->Release();  pDI=NULL;
  return 0;
}

// A flag to say whether a Joystick has been read this frame
static unsigned char JoystickRead[MAX_JOYSTICKS];
static DIJOYSTATE JoyState[MAX_JOYSTICKS];
// Call before checking for Input in a frame
int DirInputStart()
{
  // No joysticks have been Read for this frame
  memset(&JoystickRead,0,JoystickCount*sizeof(JoystickRead[0]));
  return 0;
}

// Read one of the joysticks
static INLINE int ReadJoystick(int i)
{
  int j=0,Ret=0;
  IDirectInputDevice2 *pJoy=NULL;
  if (i>=JoystickCount) return 1; // This joystick number isn't connected
  if (JoystickRead[i]) return 0; // already read this frame - ready to go

  pJoy=JoyList[i]; if (pJoy==NULL) return 1;

  // Poll + read joystick, reacquiring if neccesary
  for (j=0;j<2;j++)
  {
    pJoy->Poll();

    Ret=pJoy->GetDeviceState(sizeof(JoyState[i]),&JoyState[i]);
    if (Ret!=DIERR_INPUTLOST) break;
    pJoy->Acquire(); // if DIERR_INPUTLOST, reacquire and try again
  }
  if (Ret<0) return 1;

  // This joystick had been successfully Read this frame:
  JoystickRead[i]=1;
  return 0;
}

// Check a subcode (the 40xx bit in 4001, 4102 etc) for a joystick input code
static int JoystickState(DIJOYSTATE *pState,int SubCode)
{
  if (SubCode<5)
  {
    // A joystick direction
    switch (SubCode)
    {
      case 1: return pState->lY<0x04000;
      case 2: return pState->lY>0x0c000;
      case 3: return pState->lX<0x04000;
      case 4: return pState->lX>0x0c000;
    }
    return 0;
  }
  if (SubCode<0x10) return 0;
  if (SubCode<0x10 + DINPUT_BUTTON_COUNT) 
  {
    // A joystick button
    return (pState->rgbButtons[SubCode-0x10]&0x80) ? 1 : 0;
  }
  return 0;
}

// Get the state (pressed=1, not pressed=0) of a particular input code
int DirInputState(int Code)
{
  if (Code<0) return 0;
  if (Code<0x100)
  {
    // Return key state
    if (GetAsyncKeyState(Code)&0x8000) return 1;
    return 0;
  }

  if (Code<0x4000) return 0;
  if (Code<0x8000)
  {
    // Codes 4000-8000 = Joysticks
    int JoyNumber=0;
    JoyNumber=(Code-0x4000)>>8;
    if (ReadJoystick(JoyNumber)!=0) return 0; // There was an error polling the joystick
    // Find the joystick state in our array
    return JoystickState(JoyState+JoyNumber,Code&0xff);
  }

  return 0;
}

// This function finds which key is pressed, and returns its code
int DirInputFind()
{
  int i=0; int RetVal=-1; // assume nothing pressed
  DirInputStart(); // reset the flags which say each joystick was Read
  // check if any keyboard keys are pressed
  for (i=0;i<0x100;i++) { if (GetAsyncKeyState(i)&0x8000) { RetVal=i; goto End; } }

  // Now check all the connected joysticks
  for (i=0;i<JoystickCount;i++)
  {
    int j=0; DIJOYSTATE *pState=NULL;
    if (ReadJoystick(i)!=0) continue; // There was an error polling the joystick
    pState=JoyState+i;
    for (j=1;j<5;j++) { if (JoystickState(pState,j)) { RetVal=0x4000|(i<<8)|j; goto End; } }
    for (j=0x10;j<0x10+DINPUT_BUTTON_COUNT;j++)
    { if (JoystickState(pState,j)) { RetVal=0x4000|(i<<8)|j; goto End; } }
  }
End:
  return RetVal;
}
