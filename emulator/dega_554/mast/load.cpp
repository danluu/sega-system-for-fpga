// Mast - load module
#include "mastint.h"

int MastLoadRom(char *Name,unsigned char **pRom,int *pRomLen)
{
  FILE *h=NULL; int Len=0;
  unsigned char *Mem=NULL;
  int AllocLen=0;

  if (Name==NULL) return 1;
  if (Name[0]==0) return 1;

  h=fopen(Name,"rb"); if (h==NULL) return 1;

  fseek(h,0,SEEK_END); Len=ftell(h);

  // If it looks like there is a 0x200 byte header, skip it
  if ((Len&0x3fff)==0x0200) { Len-=0x200; fseek(h,0x200,SEEK_SET); }
  else fseek(h,0,SEEK_SET);

  AllocLen=Len;

  AllocLen+=0x3fff; AllocLen&=0x7fffc000; AllocLen+=2; // Round up to a page (+ overrun)

  Mem=(unsigned char *)malloc(AllocLen);
  if (Mem==NULL) { fclose(h); return 1; }
  memset(Mem,0,AllocLen);

  fread(Mem,1,Len,h);

  fclose(h);

  *pRom=Mem; *pRomLen=Len; // return information
  return 0;
}
