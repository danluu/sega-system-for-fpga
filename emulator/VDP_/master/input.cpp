// Input module
#include "app.h"

int UseJoystick=0;

int InputGet()
{
  static unsigned int LastInput=0;
  memset(&MastInput,0,sizeof(MastInput));
  if (GetActiveWindow()!=hFrameWnd) { LastInput=0; return 0; } // No window focus

  DirInputStart();
  if (UseJoystick==0)
  {
    // Keyboard
    if (DirInputState(VK_UP    )) MastInput[0]|=0x01;
    if (DirInputState(VK_DOWN  )) MastInput[0]|=0x02;
    if (DirInputState(VK_LEFT  )) MastInput[0]|=0x04;
    if (DirInputState(VK_RIGHT )) MastInput[0]|=0x08;
    if (DirInputState('Z'      )) MastInput[0]|=0x10;
    if (DirInputState('X'      )) MastInput[0]|=0x20;
    if (DirInputState('C'      )) MastInput[0]|=0x80;
  }
  else
  {
    // Joypad
    if (DirInputState(0x4001)) MastInput[0]|=0x01;
    if (DirInputState(0x4002)) MastInput[0]|=0x02;
    if (DirInputState(0x4003)) MastInput[0]|=0x04;
    if (DirInputState(0x4004)) MastInput[0]|=0x08;
    if (DirInputState(0x4010)) MastInput[0]|=0x10;
    if (DirInputState(0x4011)) MastInput[0]|=0x20;
    if (DirInputState(0x4012)) MastInput[0]|=0x80;
  }

  // Check start button
  if ((MastEx&MX_GG)==0)
  {
    if ((MastInput[0]&0x80) && (LastInput&0x80)==0) { MastInput[0]|=0x40; } // On master system cause nmi
  }
  LastInput=MastInput[0];
  return 0;
}
