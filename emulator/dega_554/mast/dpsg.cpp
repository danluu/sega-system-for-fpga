// Dave's PSG Sound emulator
#include "mastint.h"

int DpsgRate=0;

struct Dpsg& Dpsg=Masta.p;

struct Chan
{
  struct Sample *pSam; // Pointer to the sample we are playing for this channel
  int Pos,Add; // Position in the sample and add value
  short Vol; // Real volume
};
static struct Chan Chan[4];
static unsigned int Noise=0; // Noise value (lowest byte=position)
static int DpsgClock=3579540;
static int DpsgInc=0;

// SMS volume
short RealVol[16]=
{0x000,0x011,0x017,0x01d,0x028,0x031,0x03a,0x04b,
 0x060,0x074,0x094,0x0bd,0x0e0,0x0fc,0x0ff,0x100};

static INLINE void RecalcVol(int c)
{
  // Find real volume
  struct Chan *pc=Chan+c;
  pc->Vol=RealVol[Dpsg.Volume[c]&15];
  pc->Vol<<=4;
}

static INLINE void RecalcAdd(int c)
{
  struct Chan *pc=Chan+c;

  if (Dpsg.Period[c]<=0) return;
  if (pc->pSam==NULL)
  {
    // Start a new sample
    if (Dpsg.Period[c]>=0x9f0) pc->pSam=Sample+0; // Use square wave (After Burner speech)
    else pc->pSam=Sample+1+c; // Use instrument
    pc->Pos=0;
  }

  if (pc->pSam->PeriodCount>0)
  {
    pc->Add=pc->pSam->Len * DpsgInc / Dpsg.Period[c] / pc->pSam->PeriodCount;
  }
}

int DpsgInit()
{
  memset(&Chan,0,sizeof(Chan)); Noise=1;
  DpsgInc=0; if (DpsgRate>0) DpsgInc=(DpsgClock<<5)/DpsgRate;
  // If you increase by DpsgInc/Period, you will hit 0x400 at the end of the period

  DpsgRecalc();
  return 0;
}

int DpsgRecalc()
{
  int c=0;
  // Recalc from current state
  for (c=0;c<4;c++) { RecalcAdd(c); RecalcVol(c); }
  return 0;
}

void DpsgWrite(unsigned char d)
{
  MastSoundUpdate(); // Update sound up to here
  VgmPsg(d); // Write to disk
  if ((Dpsg.Last&0x90)==0x80)
  {
    // 1cc0pppp PPPPPPPPP : Set Channel Pitch
    int c=(Dpsg.Last>>5)&3;
    Dpsg.Period[c]&=0x00f; Dpsg.Period[c]|=d<<4; // Keep low bits and set high bits
    RecalcAdd(c);
  }

  if ((d&0x90)==0x80)
  {
    // 1cc0pppp
    int c=(d>>5)&3;
    Dpsg.Period[c]&=0xff0; Dpsg.Period[c]|=d&15;// Keep high bits and set low bits
    RecalcAdd(c);

    if (c==3) Noise=1; // Reset noise seed
  }

  if ((d&0x90)==0x90)
  {
    // 1cc1vvvv : Set Channel Volume
    int c; unsigned char v; c=(d>>5)&3; v=(unsigned char)((~d)&15);
    if (v>Dpsg.Volume[c]+2)
    { Chan[c].pSam=NULL; RecalcAdd(c); } // Louder: it's likely this is a new note
    Dpsg.Volume[c]=v;
    RecalcVol(c);
  }

  Dpsg.Last=d; // Store current byte (in case of a two byte command)
}

void DpsgStereo(unsigned char d)
{
  MastSoundUpdate(); // Update sound up to here
  VgmPsgStereo(d); // Write to disk
  Dpsg.Stereo=(unsigned char)~d;
}

static INLINE void UpdateNoise()
{
  int Type,Add; Type=Dpsg.Period[3];

  if ((Type&3)==3)
  {
    // Noise based on pitch of channel 2
    if (Dpsg.Period[2]>0) Add=DpsgInc/Dpsg.Period[2];
    else                  Add=DpsgInc<<3; // (no Chan 2 pitch)
  }
  else
  {
    // Fixed rate noise (one of three fixed rates)
    Add=DpsgInc<<(3-(Type&3));
  }

  Chan[3].Pos+=Add;

  // When the noise hits 0x400, it's time to change it
  while (Chan[3].Pos>=0x400)
  {
    if (Noise&1) 
    {
      if (Type&4) Noise^=0x12000; // White noise
      else        Noise^=0x10000; // Periodic noise
    }

    Noise>>=1;
    Chan[3].Pos-=0x400;
  }
}

void DpsgCalc(int *Total)
{
  int c;
  int Output[4]={0,0,0,0};
  unsigned char Stereo;
  int Left=0,Right=0;

  for (c=0;c<3;c++)
  {
    struct Sample *ps; int p;

    if (Chan[c].Vol<=0) continue;
    if (Dpsg.Period[c]<=4) { Output[c]=Chan[c].Vol; continue; } // speech/pstar
    ps=Chan[c].pSam; if (ps==NULL) continue; // No sample

  TryAgain:
    p=Chan[c].Pos>>10;
    // If gone past the end, loop back
    if (p>=ps->Len)
    {
      Chan[c].Pos-=ps->LoopDist<<10;
      Chan[c].Pos&=0x7ffffc00; // stop aliasing on square wave
      goto TryAgain;
    }

    // Get the sample byte
    if (p>=0) { int v; v=ps->Data[p]-0x80; Output[c]=(Chan[c].Vol*v)>>4; }
    // Increase sample pointer
    Chan[c].Pos+=Chan[c].Add;
  }

  // White noise from channel 3
  if (Noise&1) Output[3]= Chan[3].Vol;
  else         Output[3]=-Chan[3].Vol;
  UpdateNoise();

  Stereo=Dpsg.Stereo;
  for (c=0;c<4;c++,Stereo>>=1)
  {
    int p; p=Output[c];
    switch (Stereo&0x11)
    {
      default:   Left+=p;    Right+=p;    break;
      case 0x01: Left+=p;    Right+=p>>2; break;
      case 0x10: Left+=p>>2; Right+=p;    break;
      case 0x11: Left+=p>>2; Right+=p>>2; break;
    }
  }

  // Return values    
  Total[0]+=Left; Total[1]+=Right;
}
