// Mast - .vgm logging module
#include "mastint.h"

FILE *VgmFile=NULL;

static const int Chip=179208; // Cancelled down chip speed
static const int Rate=2205;   // Cancelled down 44100
static int SamWhole=0; // Whole sample counter
static int SamFrac=0;  // SamFrac/Chip extra fraction
static unsigned int SamTotal=0; // Total samples
int VgmAccurate=0; // 1=Sample accurate

int VgmStart(char *VgmName)
{
  unsigned char Buf[0x40];
  if (VgmFile!=NULL) return 1; // Already open
  VgmFile=fopen(VgmName,"wb"); if (VgmFile==NULL) return 1;

  memset(Buf,0,sizeof(Buf));
  memcpy(Buf+0x00,"Vgm ",4);      // File identification
  Buf[0x08]=0x00; Buf[0x09]=0x01; // Version number
  Buf[0x0c]=0x94; Buf[0x0d]=0x9e; Buf[0x0e]=0x36; // PSG chip speed
  Buf[0x10]=0x94; Buf[0x11]=0x9e; Buf[0x12]=0x36; // FM chip speed
  fwrite(Buf,1,sizeof(Buf),VgmFile);

  // Reset timing counter
  SamWhole=0; SamFrac=0; SamTotal=0;

  // Refresh sound emus (to set current state)
  MsndRefresh();
  return 0;
}

// Write a wait of 'v' samples
static void VgmWaitVal(int v)
{
  unsigned char Cmd[3]; int Len=0;
  if (v<=0) return;

       if (v==735) { Cmd[0]=0x62; Len=1; }
  else if (v==882) { Cmd[0]=0x63; Len=1; }
  else
  {
    Cmd[0]=0x61;
    Cmd[1]=(unsigned char) v;
    Cmd[2]=(unsigned char)(v>>8);
    Len=3;
  }
  fwrite(Cmd,1,Len,VgmFile);

  SamWhole-=v; // Subtract from todo samples
  SamTotal+=v; // Add on to total
}

static void VgmCheckWait()
{
  int Now;

  // Work out the current sample time
  Now=SamFrac+CpuMid()*Rate;
  // Current relative sample time is SamWhole + Now/Chip
  Now/=Chip;
  Now+=SamWhole;

  if (Now>882*3)
  {
    // Encode long waits
    while (Now>0xffff) { VgmWaitVal(0xffff); Now-=0xffff; }
    VgmWaitVal(Now);
    return;
  }

  if (VgmAccurate) { VgmWaitVal(Now); return; }

  // Frame accuracy
  {
    int f=735; if (MastEx&MX_PAL) f=882;
    Now/=f; if (Now<=0) return; // No need to do anything
    while (Now>0) { VgmWaitVal(f); Now--; }
  }
}

int VgmStop(unsigned short *Gd3Text)
{
  unsigned char Cmd[1];
  int Val=0;
  unsigned char Buf[0x0c];
  unsigned int GdPos=0;
  unsigned int EndPos=0;

  if (VgmFile==NULL) return 1;

  // Add on last wait
  VgmCheckWait();

  // Write the end of sound terminator
  Cmd[0]=0x66; fwrite(Cmd,1,sizeof(Cmd),VgmFile);

  if (Gd3Text!=NULL)
  {
    // Write the GD3 tag
    GdPos=ftell(VgmFile);
    memset(Buf,0,sizeof(Buf));
    memcpy(Buf,"Gd3 ",4);
    Buf[4]=0x02; Buf[5]=0x01; // GD3 version number
    Val=sizeof(Gd3Text);
    Buf[0x8]=(unsigned char) Val;
    Buf[0x9]=(unsigned char)(Val>>8);
    Buf[0xa]=(unsigned char)(Val>>16);
    Buf[0xb]=(unsigned char)(Val>>24);
    fwrite(Buf,1,sizeof(Buf),VgmFile);
    fwrite(Gd3Text,1,sizeof(Gd3Text),VgmFile);
  }

  // At the end of the file - find the current positon
  EndPos=ftell(VgmFile);
  fseek(VgmFile,0x04,SEEK_SET);
  Val=EndPos-0x04;
  Buf[0]=(unsigned char) Val;
  Buf[1]=(unsigned char)(Val>>8);
  Buf[2]=(unsigned char)(Val>>16);
  Buf[3]=(unsigned char)(Val>>24);
  fwrite(Buf,1,4,VgmFile); // Relative offset to end of file

  if (GdPos)
  {
    // Fill in the offset to the GD3 tag in the header
    fseek(VgmFile,0x14,SEEK_SET);
    Val=GdPos-0x14;
    Buf[0]=(unsigned char) Val;
    Buf[1]=(unsigned char)(Val>>8);
    Buf[2]=(unsigned char)(Val>>16);
    Buf[3]=(unsigned char)(Val>>24);
    fwrite(Buf,1,4,VgmFile); // Relative offset to GD3 tag
  }

  // Fill in the count of samples in header
  fseek(VgmFile,0x18,SEEK_SET);
  Val=SamTotal;
  Buf[0]=(unsigned char) Val;
  Buf[1]=(unsigned char)(Val>>8);
  Buf[2]=(unsigned char)(Val>>16);
  Buf[3]=(unsigned char)(Val>>24);
  fwrite(Buf,1,4,VgmFile);

  fclose(VgmFile); VgmFile=NULL;
  return 0;
}

int VgmCycleDone(int n)
{
  // Carry over cycle information into sample counter
  SamFrac +=n*Rate;
  SamWhole+=SamFrac/Chip;
  SamFrac  =SamFrac%Chip;
  return 0;
}

void VgmPsgStereo(unsigned char d)
{
  unsigned char Cmd[2];
  if (VgmFile==NULL) return;

  VgmCheckWait();
  Cmd[0]=0x4f;
  Cmd[1]=d;
  fwrite(Cmd,1,sizeof(Cmd),VgmFile);
}

void VgmPsg(unsigned char d)
{
  unsigned char Cmd[2];
  if (VgmFile==NULL) return;

  VgmCheckWait();
  Cmd[0]=0x50;
  Cmd[1]=d;
  fwrite(Cmd,1,sizeof(Cmd),VgmFile);
}

void VgmFm(unsigned char a,unsigned char d)
{
  unsigned char Cmd[3];
  if (VgmFile==NULL) return;

  VgmCheckWait();
  Cmd[0]=0x51;
  Cmd[1]=a;
  Cmd[2]=d;
  fwrite(Cmd,1,sizeof(Cmd),VgmFile);
}
