// Mast - frame module
#include "mastint.h"
#include "..\\ece554\\doze_554.h"

extern void VDPRUN(int* nDozeCycles);

int MastY=0; // 0-261
static int Hint=0; // Hint counter
static int LineCyc=0,TotalCyc=0;
static int FrameCyc=0; // Total cycles done this frame, (apart from current call)

static int CpuBase=0; // Value to subtract nDozeCycles from in order to get midcycle count

int CpuMid() // Returns how many cycles the z80 has done inside the run call
{
  return CpuBase-nDozeCycles;
}

// Run the z80 cpu for Cycles more cycles
static INLINE void CpuRun(int Cycles)
{
  int Done=0;


  nDozeCycles+=Cycles;
  
  CpuBase=nDozeCycles;

  
  VDPRUN(&nDozeCycles);


//  DozeRun_chi();
//  DozeRun();
  Done=CpuMid(); // Find out number of cycles actually done
  CpuBase=nDozeCycles; // Reset CpuBase, so CpuMid() will return 0

  FrameCyc+=Done; // Add cycles done to frame total
  VgmCycleDone(Done); // Add cycles done to VGM total
}

static void RunLine()
{
  if (MastY<=0) Hint=Masta.v.Reg[10];

  if (MastY<=192)
  {
    Hint--;
    if (Hint<0)
    {
      Masta.v.Stat|=0x40;
      if (Masta.v.Reg[0]&0x10) nDozeInterrupt=0xff; // Do hint
      Hint=Masta.v.Reg[10];
    }
  }

  if (MastY==193)
  {
    if (Masta.v.Reg[1]&0x20) nDozeInterrupt=0xff; // Do vint
  }

  CpuRun(LineCyc);
}

int MastFrame()
{

  nDozeInterrupt=Masta.Irq ? 0xff : -1; // Load IRQ latch

  if (MastEx&MX_PAL) LineCyc=273; // PAL timings (but not really: not enough lines)
  else               LineCyc=228; // NTSC timings

  TotalCyc=LineCyc*262; // For sound

  // Start counter and sound
  MsndDone=0; FrameCyc=0; nDozeCycles=0; CpuBase=0;

  // V-Int:
  Masta.v.Stat|=0x80; MastY=192; RunLine();
  for (MastY=193;MastY<262;MastY++) { RunLine(); }

  if (MastInput[0]&0x40) DozeNmi(); // Cause nmi if pause pressed

  // Active scan
  for (MastY=0;MastY<192;MastY++) { Mdraw.Line=MastY; MdrawDo(); RunLine(); }
  // Finish sound
  MsndTo(MsndLen);

  Masta.Irq = (unsigned char)(nDozeInterrupt==0xff); // Save IRQ latch

  TotalCyc=0; // Don't update sound outside of a frame
  return 0;
}

void MastSoundUpdate()
{
  int Now;
  if (TotalCyc<=0) return;
  Now=FrameCyc+CpuMid();
  MsndTo(Now*MsndLen/TotalCyc);
}
