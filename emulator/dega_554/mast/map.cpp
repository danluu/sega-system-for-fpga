// Mast - map memory module
#include "mastint.h"

int MastMapMemory()
{
  // Map in framework
#ifdef EMU_DOZE
  int i=0;

  memset(&DozeMemFetch,0,sizeof(DozeMemFetch));
  memset(&DozeMemRead, 0,sizeof(DozeMemRead));
  memset(&DozeMemWrite,0,sizeof(DozeMemWrite));

  // 0000-03ff Fixed Rom view
  for (i=0x00;i<0x04;i++)
  { DozeMemFetch[i]=DozeMemRead[i]=(unsigned int)Mastz.Rom; DozeMemWrite[i]=0; }

  // c000-dfff Ram
  for (i=0xc0;i<0xe0;i++)
  { DozeMemFetch[i]=DozeMemRead[i]=DozeMemWrite[i]=(unsigned int)pMastb->Ram-0xc000; }
  // e000-ffff Ram mirror
  for (i=0xe0;i<0x100;i++)
  { DozeMemFetch[i]=DozeMemRead[i]=DozeMemWrite[i]=(unsigned int)pMastb->Ram-0xe000; }

  // For bank writes ff00-ffff callback Doze*
  DozeMemWrite[0xff]=0;
#endif
  // Map in pages
  MastMapPage0(); MastMapPage1(); MastMapPage2();
  return 0;
}

static INLINE void CalcRomPage(int n)
{
  // Point to the rom page selected for page n
  int b; int PageOff; int Fold=0xff;
  b=Masta.Bank[1+n];
TryLower:
  PageOff=(b&Fold)<<14;
  if (PageOff+0x4000>Mastz.RomLen) // Set if the page exceeds the rom length
  {
    PageOff=0;
    if (Fold) { Fold>>=1; goto TryLower; } // (32k games, spellcaster, jungle book)
  }

  Mastz.RomPage[n]=PageOff; // Store in the Mastz structure
}

static INLINE unsigned int GetRomPage(int n)
{
  CalcRomPage(n); // Recalc the rom page
  return (unsigned int)(Mastz.Rom+Mastz.RomPage[n]); // Get the direct memory pointer
}

// 0400-3fff Page 0
void MastMapPage0()
{
  unsigned int Page; Page=GetRomPage(0);
  // Map Rom Page
#ifdef EMU_DOZE
  {
    int i=0;
    for (i=0x04;i<0x40;i++)
    {
      DozeMemFetch[i]=DozeMemRead[i]=Page;
      DozeMemWrite[i]=0;
    }
  }
#endif
}

// 4000-7fff Page 1
void MastMapPage1()
{
  unsigned int Page; Page=GetRomPage(1);
  // Map Rom Page
#ifdef EMU_DOZE
  {
    int i=0;
    Page-=0x4000;
    for (i=0x40;i<0x80;i++)
    {
      DozeMemFetch[i]=DozeMemRead[i]=Page;
      DozeMemWrite[i]=0;
    }
  }
#endif
}

// 8000-bfff Page 2
void MastMapPage2()
{
  unsigned int Page=0; int i=0;
  if (Masta.Bank[0]&0x08)
  {
    // Map Battery Ram
    Page=(unsigned int)pMastb->Sram;
    Page+=(Masta.Bank[0]&4)<<11; // Page -> 0000 or 2000
#ifdef EMU_DOZE
    Page-=0x8000;
    for (i=0x80;i<0xc0;i++)
    {
      DozeMemFetch[i]=Page;
      DozeMemRead [i]=Page;
      DozeMemWrite[i]=Page;
    }
#endif
  }
  else
  {
    // Map normal Rom Page
    Page=GetRomPage(2);
#ifdef EMU_DOZE
    Page-=0x8000;
    for (i=0x80;i<0xc0;i++)
    {
      DozeMemFetch[i]=Page;
      DozeMemRead [i]=Page;
      DozeMemWrite[i]=0;
    }
#endif
  }
}
