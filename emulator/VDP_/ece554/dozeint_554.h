


// Doze - Dave's optimized Z80 emulator
// internal code
#ifndef __DOZEINT_554_H
#define __DOZEINT_554_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "..\\mast\\doze.h"

// Make the INLINE macro
#undef INLINE
#define INLINE inline

extern "C" {
void DozeAsmRun();
extern int nDozeEi;
void DozeAsmCall(unsigned short nAddr);
}

#endif

