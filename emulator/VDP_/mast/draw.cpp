// Mast - draw module
#include "mastint.h"

struct Mdraw Mdraw;
static unsigned char qc[0x308]; // Quick color lookup from bits

int MdrawInit()
{
  static unsigned char Src[0x20]=
  {
    0x00,0x01,0x04,0x05, 0x10,0x11,0x14,0x15,
    0x02,0x03,0x06,0x07, 0x12,0x13,0x16,0x17,
    0x08,0x09,0x0c,0x0d, 0x18,0x19,0x1c,0x1d,
    0x0a,0x0b,0x0e,0x0f, 0x1a,0x1b,0x1e,0x1f
  };

  memset(&Mdraw,0,sizeof(Mdraw));

  // Make the quick color table AC 000S BD = Color SABCD
  memset(qc,0,sizeof(qc));
  memcpy(qc+0x000,Src+0x00,8); memcpy(qc+0x100,Src+0x08,8);
  memcpy(qc+0x200,Src+0x10,8); memcpy(qc+0x300,Src+0x18,8);
  return 0;
}

void MdrawCramChangeAll()
{
  int a=0;
  for (a=0;a<0x40;a++) MdrawCramChange(a);
}

// A change in CRam - update the color in Mdraw
void MdrawCramChange(int a)
{
  int s,c;
  if (pMastb==NULL) return;

  if (MastEx&MX_GG)
  {
    // Game gear color
    a>>=1; a&=0x1f; s=((unsigned short *)pMastb->CRam)[a];
    c =(s&0xe00)>>3; // -> RRR000000
    c|=(s&0x0e0)>>2; // -> 000GGG000
    c|=(s&0x00e)>>1; // -> 000000BBB
  }
  else
  {
    // Master System color
    a&=0x1f; s=pMastb->CRam[a];
    c =(s&0x30)<<3; // -> RR0000000
    c|=(s&0x0c)<<2; // -> 000GG0000
    c|=(s&0x03)<<1; // -> 000000BB0
  }
  Mdraw.Pal[a]=(unsigned short)c; Mdraw.PalChange=1;
}

static INLINE void TileLine(unsigned char *pd,unsigned int Line,char nPal)
{
  unsigned char *pe; pe=pd+8;
  do
  {
    unsigned int c;
    c=Line&0x80808080; if (c==0) goto Trans;
    c|=c>>15; // 18180
    c>>=7; c&=0x0303; *pd=qc[nPal+c];
  Trans:
    pd++; Line<<=1;
  }
  while (pd<pe);
}

static INLINE void TileFlip(unsigned char *pd,unsigned int Line,char nPal)
{
  unsigned char *pe; pe=pd+8;
  do
  {
    unsigned int c;
    c=Line&0x01010101; if (c==0) goto Trans;
    c|=c>>15; c&=0x0303; *pd=qc[nPal+c];
  Trans:
    pd++; Line>>=1;
  }
  while (pd<pe);
}

static INLINE char MdrawBackground(unsigned short nPass)
{
  unsigned char *Name; int x,BackY,BackX;
  char NeedHigh=0;
  // Find background line
  BackY=Masta.v.Reg[9]+Mdraw.Line;
  while (BackY>=224) BackY-=224;

  // Find name table
  Name=pMastb->VRam + ((Masta.v.Reg[2]<<10)&0x3800);
  // Find name table line
  Name+=(BackY>>3)<<6;

  // Find scroll X value
  if (Mdraw.Line<16 && Masta.v.Reg[0]&0x40) BackX=0; // Top two lines static
  else BackX=(-Masta.v.Reg[8])&0xff;

  for (x=8-(BackX&7); x<0x108; x+=8)
  {
    unsigned char *Tile; unsigned int Line;
    unsigned int t; char nPal; int ty;
    unsigned char *Dest;

    Dest=Mdraw.Data+8+x;
    // Find tile
    t=BackX+x-8; t>>=2; t&=0x3e; t=*((unsigned short *)(Name+t));

    if (nPass==0)
    {
      // Low pass
      // Low background is color zero of the tile (even if high)
      memset(Dest,(t&0x0800)>>7,8);
      if (t&0x1000) { NeedHigh=1; continue; } // skip and return that we need a high pass
    }
    else
    {
      // High pass
      if ((t&0x1000)==0) continue; // low tile: skip it
    }

    Tile=pMastb->VRam + ((t<<5)&0x3fe0);
    // Find tile line
    ty=BackY&7;  if (t&0x400) ty=7-ty;
    Tile+=ty<<2;
    nPal=(char)(t&0x800?4:0);
    Line=*((unsigned int *)Tile);
    
    if (t&0x200) TileFlip(Dest,Line,nPal);
    else         TileLine(Dest,Line,nPal);
  }
  return NeedHigh;
}

static INLINE void MdrawSprites()
{
  unsigned char *Sprite,*ps,*Tile;
  int i;
  // Find sprite table
  Sprite=pMastb->VRam + ((Masta.v.Reg[5]<< 7)&0x3f00);
  // Find sprite tiles
  Tile  =pMastb->VRam + ((Masta.v.Reg[6]<<11)&0x2000);
  // Find the end of the sprite list
  for (i=0,ps=Sprite; i<64; i++,ps++) { if (ps[0]==0xd0) break; } // End of sprite list
  i--;
  // Go through the sprites backwards
  for (ps=Sprite+i; i>=0; i--,ps--)
  {
    int x,y,t; unsigned int Line; unsigned char *pa; int Height;
    // Get Y coordinate
    y=ps[0]; if (y>=0xe0) y-=0x100; y++;
    if (Mdraw.Line<y) continue; // Sprite is below
    // Find sprite height
    Height=8; if (Masta.v.Reg[1]&2) Height=16;
    if (Mdraw.Line>=y+Height) continue; // Sprite is above
    // Sprite is on this line, get other info
    pa=Sprite+0x80+(i<<1); x=pa[0];
    if (Masta.v.Reg[0]&8) x-=8; // gng
    // Find sprite tile
    t=pa[1]; if (Masta.v.Reg[1]&2) t&=~1; // Even tile number (Golvellius)
    t<<=5;
    // Find sprite tile line
    t+=(Mdraw.Line-y)<<2;
    Line=*((unsigned int *)(Tile+t));
    // Draw sprite tile line
    TileLine(Mdraw.Data+16+x,Line,4);
  }
}

// Draw a scanline
void MdrawDo()
{
  int Hide=0; char NeedHigh=0;
  int Border=0;
  Mdraw.ThreeD=pMastb->ThreeD; // Mark whether this line is for the left eye or right

  Border=Masta.v.Reg[7]&0x0f; Border|=0x10;

  if (MastEx&MX_GG)
  {
    // Game gear only shows part of the height
         if (Mdraw.Line< 0x18) Hide=1;
    else if (Mdraw.Line>=0xa8) Hide=1;
  }

  if (Hide==0) { if ((Masta.v.Reg[1]&0x40)==0) Hide=1; }
  
  if (Hide) { memset(Mdraw.Data+16,Border,0x100); MdrawCall(); return; } // Line is hidden

  NeedHigh=MdrawBackground(0x0000); // low chars
  MdrawSprites();
  if (NeedHigh) MdrawBackground(0x1000); // high chars

  if (Masta.v.Reg[0]&0x20) memset(Mdraw.Data+16,Border,8); // Hide first column
  
  MdrawCall();
}
