
#include "stdafx.h"
#include "CommThread.h"


unsigned char data_to_cpu, data_from_cpu, temp_data;


#include "mastint.h"

// --------------------------  Video chip access  -----------------------------

static INLINE void VidCtrlWrite_fake(unsigned char d)
{
  int Cmd=0;
  if (Masta.v.Wait==0) { Masta.v.Low=d; Masta.v.Wait=1; return; } // low byte

  // high byte: do video command
  Cmd=d<<8; Cmd|=Masta.v.Low;
  Masta.v.Addr=(unsigned short)(Cmd&0x3fff);
  Masta.v.Mode=(unsigned char)((Cmd>>14)&3); // 0-2=VRAM read/write 3=CRAM write

//	outfile << "Address :" << " " << (Cmd&0x3fff) << endl;
//	outfile << "Mode :" << " " << ((Cmd>>14)&3) << endl;


  if ((Cmd&0xf000)==0x8000)
  {
    // Video register set
    int i;
    i=(Cmd>>8)&0x3f;
    if (i<0x10) Masta.v.Reg[i]=(unsigned char)(Cmd&0xff);
//	outfile << "Register[" << i << "]: " << (Cmd&0xff) << endl;
  }
  
  Masta.v.Wait=0; nDozeInterrupt=-1;
}

static INLINE unsigned char VidCtrlRead_fake()
{
  unsigned char d=0;
  d=Masta.v.Stat; d|=0x20;

  Masta.v.Wait=0; Masta.v.Stat&=0x3f; nDozeInterrupt=-1;
  return d;
}

// -----------------------------------------------------------------------------

static INLINE void VidDataWrite_fake(unsigned char d)
{
  if (Masta.v.Mode==3)
  {
    // CRam Write
    unsigned char *pc;
    pc=pMastb->CRam+(Masta.v.Addr&0x3f);
    if (pc[0]!=d) { pc[0]=d; MdrawCramChange(Masta.v.Addr); }  // CRam byte change

//	outfile << "CRam Write: " << (Masta.v.Addr) << " with  " << (unsigned int) d << endl;
  }
  else
  {
    pMastb->VRam[Masta.v.Addr&0x3fff]=d;

//	outfile << "VRam Write: " << (Masta.v.Addr&0x3fff) << " with  " << (unsigned int) d << endl;
  }
  Masta.v.Addr++; // auto increment address
  Masta.v.Wait=0;
}

static INLINE unsigned char VidDataRead_fake()
{
  unsigned char d=0;
  d=pMastb->VRam[Masta.v.Addr&0x3fff];
  Masta.v.Addr++; // auto increment address
  Masta.v.Wait=0;
  return d;
}

// =============================================================================
static INLINE unsigned char SysIn_fake(unsigned short a)
{
  unsigned char d=0xff;
  a&=0xff; // 8-bit ports
  if (a==0x00)
  {
    d=0x7f; if ((MastInput[0]&0x80)==0) d|=0x80; // Game gear start button
    goto End;
  }
  if (a==0x05) { d=0; goto End; } // Link-up
  if (a==0x7e)
  {
    // V-Counter read
    if (MastY>0xda) d=(unsigned char)(MastY-6);
    else            d=(unsigned char) MastY;
    goto End;
  }
  if (a==0x7f)
  {
    // H-Counter read: return about the middle
    d=0x40;
    goto End;
  }
  if (a==0xbe) { d=VidDataRead_fake(); goto End; }
  if (a==0xbf) { d=VidCtrlRead_fake(); goto End; }
  if (a==0xdc || a==0xc0)
  {
    // Input
    d=MastInput[0]; d&=0x3f;
    d=(unsigned char)(~d);
    goto End;
  }
  if (a==0xdd || a==0xc1)
  {
    // Region detect:
    d=0x3f;
    d|=pMastb->Out3F&0x80; // bit 7->7
    d|=(pMastb->Out3F<<1)&0x40; // bit 5->6
    if (MastEx&MX_JAPAN) d^=0xc0; //select japanese
    goto End;
  }
  if (a==0xf2)
  {
    // Fm Detect
    d=0xff;
    if (MastEx&MX_FMCHIP) { d=pMastb->FmDetect; d&=1; }
    goto End;
  }
End:
  return d;
}

static INLINE void SysOut_fake(unsigned short a,unsigned char d)
{
  a&=0xff; // 8-bit ports
  if ( a      ==0x06) { DpsgStereo(d);   goto End; } // Psg Stereo
  if ( a      ==0x3f) { pMastb->Out3F=d; goto End; } // Region detect
  if ((a&0xfe)==0x7e) { DpsgWrite(d); goto End; } // Psg Write
  if ( a      ==0xbe) { VidDataWrite_fake(d); goto End; }
  if ( a      ==0xbf) { VidCtrlWrite_fake(d); goto End; }
  if ( a      ==0xf0) { pMastb->FmSel=d; goto End; }
  if ( a      ==0xf1) { MsndFm(pMastb->FmSel,d); goto End; }
  if ( a      ==0xf2) { pMastb->FmDetect=d; goto End; }
End:
  return;
}



unsigned char DozeIn_fake(unsigned short a)            
{
	unsigned char d = SysIn_fake(a);
	return d; 
}
void DozeOut_fake(unsigned short a, unsigned char d)   
{ 

	SysOut_fake(a,d); 
}
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////


unsigned short getport(unsigned char data)
{
	switch (data&0x03)
	{
	case 0x00:
		return 0xbf; break;
	case 0x01:
		return 0xbe; break;
	case 0x02:
		return 0x7f; break;
	case 0x03:
		return 0x7e; break;
	}	
}

void VDPRUN()
{
	if( !m_ComuPort.OpenPort( "COM1", 9600, 1 ) )
	{
		exit(0); //	Cannot get the port !!!  EXIT
	}
//	while(1)
//	{
		if (m_ComuPort.ReadComm( &data_from_cpu, 1))
		{
			int fail_write = 0;
			if ((data_from_cpu & 0x04)==0x04)		// In Instruction
			{
				data_to_cpu = SysIn_fake(getport(data_from_cpu));
				fail_write = (int)m_ComuPort.WriteComm( &data_to_cpu, 1);
				if (fail_write)
				{
					exit(0); //	Cannot write on the port !!!  EXIT
				}
			}
			else if((data_from_cpu & 0x04)==0x00)		// Out Instruction
			{
				int ready = 0;
				temp_data = data_from_cpu;
				while (ready)
				{
					ready = m_ComuPort.ReadComm( &data_from_cpu, 1);
				}
				SysOut_fake(getport(temp_data), data_from_cpu);
			}
		}
//	}
	m_ComuPort.ClosePort();
}