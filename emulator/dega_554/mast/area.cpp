// Mast - state area module
#include "mastint.h"

int MastAcbNull (struct MastArea *pba) { (void)pba; return 1; }
int (*MastAcb) (struct MastArea *pma)=MastAcbNull; // Area callback

// Scan the information stored in non-volatile memory
int MastAreaBattery()
{
  struct MastArea ma;
  memset(&ma,0,sizeof(ma));
  if (pMastb==NULL) return 1;

  ma.Data=pMastb->Sram;
  ma.Len=sizeof(pMastb->Sram);
  MastAcb(&ma);
  return 0;
}

// Scan the information stored in volatile memory
// Dega state style
int MastAreaDega()
{
  struct MastArea ma;
  unsigned char Blank[0x100];
  unsigned int FileVer=0;
  if (pMastb==NULL) return 1;

  memset(&ma,0,sizeof(ma));
  memset(Blank,0,sizeof(Blank));

  // 0x0000 File ID
  {
    char Id[5]="Dega";
    ma.Data=Id; ma.Len=4; MastAcb(&ma);
    if (memcmp(Id,"Dega",4)!=0) return 1; // Check ID is okay
  }

  FileVer=MastVer;
  ma.Data=&FileVer; ma.Len=sizeof(FileVer); MastAcb(&ma); // 0x0004: Version number
  ma.Data=Blank;    ma.Len=0x10-0x08;       MastAcb(&ma); // reserved

  ma.Data=&Doze;    ma.Len=sizeof(Doze);    MastAcb(&ma); // 0x0010: Z80 registers
  ma.Data=Blank;    ma.Len=0x30-0x1e;       MastAcb(&ma); // reserved

  ma.Data=&Masta;   ma.Len=sizeof(Masta);   MastAcb(&ma); // 0x0040: Masta
  ma.Data=Blank;    ma.Len=0x40-0x2c;       MastAcb(&ma); // reserved

  // 0x0080: pMastb
  ma.Data=pMastb->Ram; ma.Len=sizeof(*pMastb)-0x4000; // Exclude sram
  MastAcb(&ma);
  ma.Data=Blank;    ma.Len=0x100-0x04;      MastAcb(&ma); // reserved

  // Update banks, colors and sound
  MastMapPage0(); MastMapPage1(); MastMapPage2();
  MdrawCramChangeAll();
  MsndRefresh();
  return 0;
}

// Meka style (S00)
int MastAreaMeka()
{
  struct MastArea ma;

  if (pMastb==NULL) return 1;

  memset(&ma,0,sizeof(ma));

  // Blank unsaved parts of state
  Masta.v.Stat=0;
  Masta.v.Mode=0;
  Masta.Irq=0;
  memset(&Masta.p,0,sizeof(Masta.p)); // PSG not saved
  pMastb->Out3F=0;
  pMastb->ThreeD=0;
  pMastb->FmSel=0;
  pMastb->FmDetect=0;
  memset(&(pMastb->FmReg),0,sizeof(pMastb->FmReg));
  Doze.ir=0;
  // Scan state

  // 0000
  {
    char Id[5]="MEKA";
    ma.Data=Id; ma.Len=4; MastAcb(&ma);
    if (memcmp(Id,"MEKA",4)!=0) return 1; // Check ID is okay
  }

  // 0004
  {
    unsigned char Unknown[3]={0x1a,0x07,0x00};
    ma.Data=Unknown; ma.Len=sizeof(Unknown); MastAcb(&ma);
  }
  // 0007

  ma.Len=2;
#define SC(regname) ma.Data=&(Doze.regname); MastAcb(&ma);
  SC(af)  SC(bc)  SC(de)  SC(hl)  SC(ix) SC(iy) SC(pc) SC(sp)
  SC(af2) SC(bc2) SC(de2) SC(hl2)
#undef SC

  // 001f
  {
    unsigned char Int=0;
    // compress Interrupt state into three bits
    if (Doze.iff) Int=1;  Int|=Doze.im<<1;
    
    Int&=7; ma.Data=&Int; ma.Len=1; MastAcb(&ma); Int&=7;

    // deompress interrupt state
    Doze.iff=0; if (Int&1) Doze.iff=0x0101;
    Doze.im=(unsigned char)(Int>>1);
  }

  // 0020
  {
    unsigned char Unknown[0x1b]=
    {0x00,0x00,0x00,0xe4, 0x00,0x00,0x00,0xfe, 0xff,0xff,0xff,0x00, 0x00,0x00,0x00,0x38,
     0x00,0x00,0x00,0xff, 0xff,0x00,0x00,0x00, 0x00,0x00,0x00};
    ma.Data=Unknown; ma.Len=sizeof(Unknown); MastAcb(&ma);
  }


  // 003b VDP Registers
  Masta.v.Reg[6]&=7;
  ma.Data=Masta.v.Reg; ma.Len=0x10; MastAcb(&ma);
  Masta.v.Reg[6]&=7;

  // 004b
  {
    unsigned char Unknown[2]={0x00,0xa0};
    ma.Data=Unknown; ma.Len=sizeof(Unknown); MastAcb(&ma);
  }

  // 004d Vram write address
  ma.Data=&Masta.v.Addr; ma.Len=2; MastAcb(&ma);

  // 004f Waiting for high byte
  ma.Data=&Masta.v.Wait; ma.Len=1; MastAcb(&ma);

  // 0050 Low byte written to port bf
  ma.Data=&Masta.v.Low;  ma.Len=1; MastAcb(&ma);

  // 0051 Last byte written to port be
  {
    unsigned char DontCare=0;
    ma.Data=&DontCare; ma.Len=1; MastAcb(&ma);
  }

  // 0052
  {
    unsigned char Unknown[13]=
    {0x00,0x00,0x00,0x00, 0x00,0x06,0x00,0x00, 0x00,0x01,0x00,0x01, 0x00};
    ma.Data=Unknown; ma.Len=sizeof(Unknown); MastAcb(&ma);
  }

  // 005f
  ma.Data=Masta.Bank+0; ma.Len=1; MastAcb(&ma);
  {
    unsigned char Unknown[3]={0,0,7};
    ma.Data=Unknown; ma.Len=sizeof(Unknown); MastAcb(&ma);
  }

  // 0063
  ma.Data=Masta.Bank+1; ma.Len=3; MastAcb(&ma);
  {
    unsigned char Unknown=0;
    ma.Data=&Unknown; ma.Len=1; MastAcb(&ma);
  }

  // 0067
  ma.Data=pMastb->Ram; ma.Len=0x2000; MastAcb(&ma);
  // 2067
  ma.Data=pMastb->VRam; ma.Len=0x4000; MastAcb(&ma);
  // 6067
  ma.Data=pMastb->CRam; ma.Len=0x0040; MastAcb(&ma);

  // 60a7-60cb unknown and EOF
  {
    unsigned char End[0x24];
    memset(End,0,sizeof(End));
    End[0x21]='E'; End[0x22]='O'; End[0x23]='F';
    ma.Data=End; ma.Len=sizeof(End); MastAcb(&ma);
  }

  // Update banks, colors and sound
  MastMapPage0(); MastMapPage1(); MastMapPage2();
  MdrawCramChangeAll();
  MsndRefresh();
  return 0;
}
