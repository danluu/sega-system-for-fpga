/////////////////////////////////////////////////////
// RF.v
// register file of z80
// in addition to architected registers of original
// z80, it contains T0 ~ T3, which are temporary
// registers that contains intermediate
// computation results
// this unit also inplement forwarding between
// 8 / 16bit registers.
//
// Dec, 2002
// Written by ikim
/////////////////////////////////////////////////////
module RF(CLK, RST, Rd0_id, Rd1_id, Rd_data0, Rd_data1, Wr_id, Wr_data, Fmask, F_data);
input CLK, RST;
input [4:0] Rd0_id, Rd1_id, Wr_id;
input [7:0] Fmask, F_data;
input [15:0] Wr_data;
output [15:0] Rd_data0, Rd_data1;

`include "uISA.def.v"

// outputs
reg [15:0] Rd_data0, Rd_data1;

// memory elements
reg [7:0] FF_A, FF_F, FF_B, FF_C, FF_D, FF_E, FF_H, FF_L, FF_I, FF_R, FF_T0, FF_T1, FF_T2, FF_T3;
reg [15:0] FF_SP, FF_IX, FF_IY, FF_AFs, FF_BCs, FF_DEs, FF_HLs;

// hardwired 0 register
wire [15:0] Reg0;
assign Reg0 = 16'b0;

// next state variables
reg [7:0] nFF_A, nFF_F, nFF_B, nFF_C, nFF_D, nFF_E, nFF_H, nFF_L, nFF_I, nFF_R, nFF_T0, nFF_T1, nFF_T2, nFF_T3;
reg [15:0] nFF_SP, nFF_IX, nFF_IY, nFF_AFs, nFF_BCs, nFF_DEs, nFF_HLs;

// synchronous part: reset & writing values
always@(posedge CLK)
begin
  if(RST)
  begin
      FF_A <= 8'H00;
      FF_F <= 8'H40;
      FF_B <= 8'b0;
      FF_C <= 8'b0;
      FF_D <= 8'b0;
      FF_E <= 8'b0;
      FF_H <= 8'b0;
      FF_L <= 8'b0;
      FF_I <= 8'b0;
      FF_R <= 8'b0;
      FF_T0 <= 8'b0;
      FF_T1 <= 8'b0;
      FF_T2 <= 8'b0;
      FF_T3 <= 8'b0;
      FF_SP <= 16'HDFF0;
      FF_IX <= 16'HFFFF;
      FF_IY <= 16'HFFFF;
      FF_AFs <= 16'b0;
      FF_BCs <= 16'b0;
      FF_DEs <= 16'b0;
      FF_HLs <= 16'b0;
    end
  else
    begin
      FF_A <= nFF_A;
      FF_F <= nFF_F;
      FF_B <= nFF_B;
      FF_C <= nFF_C;
      FF_D <= nFF_D;
      FF_E <= nFF_E;
      FF_H <= nFF_H;
      FF_L <= nFF_L;
      FF_I <= nFF_I;
      FF_R <= nFF_R;
      FF_T0 <= nFF_T0;
      FF_T1 <= nFF_T1;
      FF_T2 <= nFF_T2;
      FF_T3 <= nFF_T3;
      FF_SP <= nFF_SP;
      FF_IX <= nFF_IX;
      FF_IY <= nFF_IY;
      FF_AFs <= nFF_AFs;
      FF_BCs <= nFF_BCs;
      FF_DEs <= nFF_DEs;
      FF_HLs <= nFF_HLs;
    end
end

// sign extension
function [15:0] SIGN_EXT;
input [7:0] i;
begin
  SIGN_EXT = {i[7],i[7],i[7],i[7],i[7],i[7],i[7],i[7],i[7:0]};
end
endfunction

// Flag write: FWRITE(flag mask, flag data)
task FWRITE;
input [7:0] FMASK;
input [7:0] FDATA;
begin
  nFF_F = (FF_F & (~FMASK)) | (FDATA & FMASK);
end
endtask

// writing part: REGWRITE(register id, write value)
task REGWRITE;
input [4:0] REG_ID;
input [15:0] VALUE;
begin
  case(REG_ID)
    rR0:
      begin
      end
    rA:
      nFF_A = VALUE[7:0];
    rF:
      nFF_F = VALUE[7:0];
    rB:
      nFF_B = VALUE[7:0];
    rC:
      nFF_C = VALUE[7:0];
    rD:
      nFF_D = VALUE[7:0];
    rE:
      nFF_E = VALUE[7:0];
    rH:
      nFF_H = VALUE[7:0];
    rL:
      nFF_L = VALUE[7:0];
    rI:
      nFF_I = VALUE[7:0];
    rR:
      nFF_R = VALUE[7:0];
    rT0:
      nFF_T0 = VALUE[7:0];
    rT1:
      nFF_T1 = VALUE[7:0];
    rT2:
      nFF_T2 = VALUE[7:0];
    rT3:
      nFF_T3 = VALUE[7:0];

    rSP:
      nFF_SP = VALUE[15:0];
    rAF:
      begin
        nFF_A = VALUE[15:8];
        nFF_F = VALUE[7:0];
      end
    rBC:
      begin
        nFF_B = VALUE[15:8];
        nFF_C = VALUE[7:0];
      end
    rDE:
      begin
        nFF_D = VALUE[15:8];
        nFF_E = VALUE[7:0];
      end
    rHL:
      begin
        nFF_H = VALUE[15:8];
        nFF_L = VALUE[7:0];
      end
    rIX:
      nFF_IX = VALUE[15:0];
    rIY:
      nFF_IY = VALUE[15:0];
    rT10:
      begin
        nFF_T1 = VALUE[15:8];
        nFF_T0 = VALUE[7:0];
      end
    rT32:
      begin
        nFF_T3 = VALUE[15:8];
        nFF_T2 = VALUE[7:0];
      end
    rAFs:
      nFF_AFs = VALUE[15:0];
    rBCs:
      nFF_BCs = VALUE[15:0];
    rDEs:
      nFF_DEs = VALUE[15:0];
    rHLs:
      nFF_HLs = VALUE[15:0];
 
    default:
      begin
      end
  endcase
end
endtask

// Flag write: FWRITE(flag mask, flag data)
// writing part: REGWRITE(register id, write value)
// nFF_?? generator for write
always@(Wr_id or Wr_data or Fmask or F_data		// external inputs
 or FF_A or FF_F or FF_B or FF_C or FF_D or FF_E or FF_H or FF_L or FF_I or FF_R or FF_T0 or FF_T1 or FF_T2 or FF_T3
 or FF_SP or FF_IX or FF_IY or FF_AFs or FF_BCs or FF_DEs or FF_HLs)
begin
  // initialize nFF_??
  nFF_A = FF_A;
  nFF_F = FF_F;
  nFF_B = FF_B;
  nFF_C = FF_C;
  nFF_D = FF_D;
  nFF_E = FF_E;
  nFF_H = FF_H;
  nFF_L = FF_L;
  nFF_I = FF_I;
  nFF_R = FF_R;
  nFF_T0 = FF_T0;
  nFF_T1 = FF_T1;
  nFF_T2 = FF_T2;
  nFF_T3 = FF_T3;
  nFF_SP = FF_SP;
  nFF_IX = FF_IX;
  nFF_IY = FF_IY;
  nFF_AFs = FF_AFs;
  nFF_BCs = FF_BCs;
  nFF_DEs = FF_DEs;
  nFF_HLs = FF_HLs;

  // write flags
  FWRITE  (Fmask, F_data);
  // write register
  REGWRITE(Wr_id, Wr_data);

end

// reading part
// REGREAD(read register ID)
// now, we have to also deal with data forwarding from writing data.
// by outputing nFF_?? instead of FF_??
function [15:0] REGREAD;
input [4:0] REG_ID;
begin
  case(REG_ID)
    rR0:
      REGREAD = 16'b0;
    rA:
      REGREAD = SIGN_EXT(nFF_A);
    rF:
      REGREAD = SIGN_EXT(nFF_F);
    rB:
      REGREAD = SIGN_EXT(nFF_B);
    rC:
      REGREAD = SIGN_EXT(nFF_C);
    rD:
      REGREAD = SIGN_EXT(nFF_D);
    rE:
      REGREAD = SIGN_EXT(nFF_E);
    rH:
      REGREAD = SIGN_EXT(nFF_H);
    rL:
      REGREAD = SIGN_EXT(nFF_L);
    rI:
      REGREAD = SIGN_EXT(nFF_I);
    rR:
      REGREAD = SIGN_EXT(nFF_R);
    rT0:
      REGREAD = SIGN_EXT(nFF_T0);
    rT1:
      REGREAD = SIGN_EXT(nFF_T1);
    rT2:
      REGREAD = SIGN_EXT(nFF_T2);
    rT3:
      REGREAD = SIGN_EXT(nFF_T3);

    rSP:
      REGREAD = nFF_SP;
    rAF:
      REGREAD = {nFF_A, nFF_F};
    rBC:
      REGREAD = {nFF_B, nFF_C};
    rDE:
      REGREAD = {nFF_D, nFF_E};
    rHL:
      REGREAD = {nFF_H, nFF_L};
    rIX:
      REGREAD = nFF_IX;
    rIY:
      REGREAD = nFF_IY;
    rT10:
      REGREAD = {nFF_T1, nFF_T0};
    rT32:
      REGREAD = {nFF_T3, nFF_T2};
    rAFs:
      REGREAD = nFF_AFs;
    rBCs:
      REGREAD = nFF_BCs;
    rDEs:
      REGREAD = nFF_DEs;
    rHLs:
      REGREAD = nFF_HLs;
    default:
      REGREAD = 16'bx;
  endcase
end
endfunction

// REGREAD(read register ID)
// read dta 0 and 1  
always@(Rd0_id or Rd1_id 		// external inputs
 or nFF_A or nFF_F or nFF_B or nFF_C or nFF_D or nFF_E or nFF_H or nFF_L or nFF_I or nFF_R or nFF_T0 or nFF_T1 
 or nFF_T2 or nFF_T3 or nFF_SP or nFF_IX or nFF_IY or nFF_AFs or nFF_BCs or nFF_DEs or nFF_HLs)
begin
  Rd_data0 = REGREAD(Rd0_id);
  Rd_data1 = REGREAD(Rd1_id);
end

endmodule
