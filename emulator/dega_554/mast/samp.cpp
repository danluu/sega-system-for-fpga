// Samples for PSG enhancement
#include "mastint.h"
#include "samples.h"

#define SAMP_COUNT (5)

int MastPsgEnhance=0;

static unsigned char Square[0x80];
struct Sample Sample[SAMP_COUNT]=
{
  {NULL,0,0},
  {NULL,0,0},
  {NULL,0,0},
  {NULL,0,0},
  {NULL,0,0}
};

// Reset to the default square sample
static void SampReset(struct Sample *ps)
{ ps->Data=Square; ps->Len=sizeof(Square); ps->PeriodCount=1; ps->LoopDist=ps->Len; }

int SampInit()
{
  int i; struct Sample *ps;

  // Make default square wave  
  for (i=0;i<sizeof(Square);i++)
  {
    int p=0x80;
    if (i < sizeof(Square)>>1) p-=0x14; else p+=0x14;
    Square[i]=(unsigned char)p;
  }

  // Reset to all point at Square
  memset(&Sample,0,sizeof(Sample));
  for (i=0,ps=Sample; i<SAMP_COUNT; i++,ps++) SampReset(ps);

  if (MastPsgEnhance)
  {
    // Use the samples built into the exe
    ps=Sample+1;
    ps->Data=DspSample; ps->Len=sizeof(DspSample);
    ps->PeriodCount=292;  ps->LoopDist=sizeof(DspSample)>>1;  ps++;

    ps->Data=MoogSample; ps->Len=sizeof(MoogSample);
    ps->PeriodCount=33*2; ps->LoopDist=672;  ps++;
  }

  return 0;
}

int SampExit()
{
  int i; struct Sample *ps;
  // Reset samples
  for (i=0,ps=Sample; i<SAMP_COUNT; i++,ps++)
  {
    SampReset(ps);
  }
  return 0;
}
