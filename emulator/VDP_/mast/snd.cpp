// Mast - sound module
#include "mastint.h"

int MsndRate=0; // sample rate of sound
int MsndLen=0;  // length in samples per frame
short *pMsndOut=NULL; // pointer to sound output buffer or NULL for no sound

int MsndDone=0; // Sound rendered so far this frame
OPLL *MastOpl=NULL;

int MsndInit()
{
  SampInit();
  DpsgRate=MsndRate; DpsgInit();

  // Init FM sound
  MastOpl=NULL;
  if (MsndRate>=4000)
  {
    OPLL_init(3579540,MsndRate); MastOpl=OPLL_new();
  }

  MsndRefresh();
  return 0;
}

int MsndRefresh()
{
  int c=0; unsigned char d=0;
  // Write current PSG state into PSG emulator
  d=Masta.p.Stereo; d^=0xff; DpsgStereo(d);
  for (c=0;c<4;c++)
  {
    // Volume 1cc1vvvv
    d=(unsigned char)Masta.p.Volume[c]; d^=15; d|=0x90; d|=c<<5;
    DpsgWrite(d);
  }
  for (c=0;c<4;c++)
  {
    // Period 1cc1pppp PPPPPPPP
    d=(unsigned char)Masta.p.Period[c]; d&=0x0f; d|=0x80; d|=c<<5;
    DpsgWrite(d);
    d=(unsigned char)Masta.p.Period[c]; d>>=4;
    DpsgWrite(d);
  }

  // Write current FM state into FM emulator
  if (MastOpl==NULL) return 0;
  OPLL_reset_patch(MastOpl,0);

  if (pMastb!=NULL)
  {
    unsigned char a=0;
    for (a=0;a<0x40;a++)
    {
      if (a==0x0e) continue; // Skip drums
      MsndFm(a,pMastb->FmReg[a]);
    }
  }
  return 0;
}

int MsndExit()
{
  // Exit FM sound
  if (MastOpl!=NULL) { OPLL_delete(MastOpl); OPLL_close(); }
  MastOpl=NULL;

  DpsgRate=0;
  SampExit();
  return 0;
}

void MsndStart()
{
  MsndDone=0;
}

void MsndTo(int To)
{
  short *Dest; int Len;
  short *pd,*pe;
  if (pMsndOut==NULL) return;
  if (To<=MsndDone) return; // Already done
  if (MsndDone>MsndLen) MsndDone=MsndLen;

  Dest=pMsndOut+(MsndDone<<1); Len=To-MsndDone;
  memset(Dest,0,Len<<2);
  
  // FM sound
  pd=Dest; pe=pd+(Len<<1);
  do
  {
    int c[2];
    c[0]=0;

    if (MastEx&MX_FMCHIP) 
    { if (MastOpl!=NULL) c[0]=OPLL_calc(MastOpl)<<2; } // Get FM sound

    c[1]=c[0];
    DpsgCalc(c); // Add PSG sound

#define CLIP(x) if (x>0x7fff) x=0x7fff; if (x<-0x8000) x=-0x8000;
    CLIP(c[0]) CLIP(c[1])

    *pd++=(short)c[0]; *pd++=(short)c[1];
  }
  while (pd<pe);

  MsndDone=To;
}

void MsndFm(unsigned char a,unsigned char d)
{
  if ((MastEx&MX_FMCHIP)==0) return; // No fm chip

  MastSoundUpdate();

  a&=0x3f;
  pMastb->FmReg[a]=d;

  VgmFm(a,d); // Log to VGM
  if (MastOpl!=NULL) OPLL_writeReg(MastOpl,a,d);
}
