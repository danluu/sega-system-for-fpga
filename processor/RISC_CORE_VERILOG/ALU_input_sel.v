/////////////////////////////////////////////////
// ALU_input_sel.v
//
// Forwarding unit
// Written by ikim
/////////////////////////////////////////////////

module ALU_input_sel (Src0, Src1,
       Rd_data0, Rd0_id, Rd_data1, Rd1_id,
       MEM_Result, MEM_Wr_id, MEM_Flags, MEM_Fmask,
       WB_Result, WB_Wr_id, WB_Flags, WB_Fmask);

output [15:0] Src0, Src1;
input [15:0] Rd_data0, Rd_data1;
input [4:0] Rd0_id, Rd1_id;
input [15:0] MEM_Result, WB_Result;
input [4:0] MEM_Wr_id, WB_Wr_id;
input [7:0] MEM_Flags, MEM_Fmask, WB_Flags, WB_Fmask;

reg [15:0] Src0, Src1;

// temp variable
reg [15:0] out0, out1;

// include register identifiers
`include "uISA.def.v"

// The basic operation of this module is simple: make the
// ALU read the most recent version of register values.
// To do so, this keep track of register/Fmask bit depencences
// and find the most recent updates, and merge them into
// the current register value (or sometimes overwrite)

// As the first step, the following routines deal with 
// reg to reg forwarding. Later, bit-wise F register merging
// will be implemented.

// in theory, there is a case where ???_Wr_id is F and ???_Fmask
// is also non-zero in the same stage, which implies that there
// is a collision in writing values to F.
// we assume that Fmask overrides Wr_id of F. So, F is updated by
// the ALU value first, and bits specified in Fmask are overwritten.
// RF should apply the same policy as here.
// However, I believe xlator does not generate instructions like this.


// REG name convertion
function [4:0] CONV_REG_H;
input [4:0] REGID;
begin
  casez(REGID)
    5'b0????:
      CONV_REG_H = rR0;
    rAF:
      CONV_REG_H = rA;
    rBC:
      CONV_REG_H = rB;
    rDE:
      CONV_REG_H = rD;
    rHL:
      CONV_REG_H = rH;
    rT10:
      CONV_REG_H = rT1;
    rT32:
      CONV_REG_H = rT3;
    default:
      CONV_REG_H = REGID;
   endcase
end
endfunction

function [4:0] CONV_REG_L;
input [4:0] REGID;
begin
  casez(REGID)
    rAF:
      CONV_REG_L = rF;
    rBC:
      CONV_REG_L = rC;
    rDE:
      CONV_REG_L = rE;
    rHL:
      CONV_REG_L = rL;
    rT10:
      CONV_REG_L = rT0;
    rT32:
      CONV_REG_L = rT2;
    default:
      CONV_REG_L = REGID;
   endcase
end
endfunction

function [7:0] BYPASS_L;
input[4:0] REGID_EXE_L;
input[4:0] REGID_MEM_L;
input[4:0] REGID_MEM_H;
input[4:0] REGID_WB_L;
input[4:0] REGID_WB_H;
input[7:0] VAL_EXE_L;
input[7:0] VAL_MEM_L;
input[7:0] VAL_MEM_H;
input[7:0] VAL_WB_L;
input[7:0] VAL_WB_H;
begin
  casez({(REGID_EXE_L == REGID_MEM_L), (REGID_EXE_L == REGID_MEM_H),
         (REGID_EXE_L == REGID_WB_L), (REGID_EXE_L == REGID_WB_H)})
    4'b1???:
      BYPASS_L = VAL_MEM_L;
    4'b01??:
      BYPASS_L = VAL_MEM_H;
    4'b001?:
      BYPASS_L = VAL_WB_L;
    4'b0001:
      BYPASS_L = VAL_WB_H;
    default:
      BYPASS_L = VAL_EXE_L;
  endcase
end
endfunction

function [7:0] BYPASS_H;
input[4:0] REGID_EXE_H;
input[4:0] REGID_MEM_L;
input[4:0] REGID_MEM_H;
input[4:0] REGID_WB_L;
input[4:0] REGID_WB_H;
input[7:0] VAL_EXE_H;
input[7:0] VAL_MEM_L;
input[7:0] VAL_MEM_H;
input[7:0] VAL_WB_L;
input[7:0] VAL_WB_H;
begin
  casez({(REGID_EXE_H == REGID_MEM_H), (REGID_EXE_H == REGID_MEM_L),
         (REGID_EXE_H == REGID_WB_H), (REGID_EXE_H == REGID_WB_L)})
    4'b1???:
      BYPASS_H = VAL_MEM_H;
    4'b01??:
      BYPASS_H = VAL_MEM_L;
    4'b001?:
      BYPASS_H = VAL_WB_H;
    4'b0001:
      BYPASS_H = VAL_WB_L;
    default:
      BYPASS_H = VAL_EXE_H;
  endcase
end
endfunction

// flag forward, do it by one by one bit
// REGID_EXE is F, already.
function BYPASS_F;
input      FMASK_MEM;
input[4:0] REGID_MEM_L;
input      FMASK_WB;
input[4:0] REGID_WB_L;
input      FLAG_EXE;
input      FLAG_MEM;
input      VAL_MEM_L;
input      FLAG_WB;
input      VAL_WB_L;
begin
  casez({FMASK_MEM, (REGID_MEM_L == rF), FMASK_WB, (REGID_WB_L == rF)})
    4'b1???:
      BYPASS_F = FLAG_MEM;
    4'b01??:
      BYPASS_F = VAL_MEM_L;
    4'b001?:
      BYPASS_F = FLAG_WB;
    4'b0001:
      BYPASS_F = VAL_WB_L;
    default:
      BYPASS_F = FLAG_EXE;
  endcase
end
endfunction

// temp reg
reg[4:0] reg0_exe_l, reg0_exe_h, reg1_exe_l, reg1_exe_h, reg_mem_l, reg_mem_h, reg_wb_l, reg_wb_h;

always@(Rd_data0 or Rd0_id or Rd_data1 or Rd1_id or MEM_Result or WB_Result
        or MEM_Wr_id or WB_Wr_id or MEM_Flags or MEM_Fmask or WB_Flags or WB_Fmask)
begin
  reg0_exe_l = CONV_REG_L(Rd0_id);
  reg0_exe_h = CONV_REG_H(Rd0_id);
  reg1_exe_l = CONV_REG_L(Rd1_id);
  reg1_exe_h = CONV_REG_H(Rd1_id);
  
  reg_mem_l = CONV_REG_L(MEM_Wr_id);
  reg_mem_h = CONV_REG_H(MEM_Wr_id);
  
  reg_wb_l = CONV_REG_L(WB_Wr_id);
  reg_wb_h = CONV_REG_H(WB_Wr_id);
  
  /* low portion bypass */
  /* check if reg0_exe_l and reg1_exe_l are F */
  if(reg0_exe_l == rF)
    begin
      out0[0] = BYPASS_F (             MEM_Fmask[0], reg_mem_l,     WB_Fmask[0], reg_wb_l, 
                          Rd_data0[0], MEM_Flags[0], MEM_Result[0], WB_Flags[0], WB_Result[0]);
      out0[1] = BYPASS_F (             MEM_Fmask[1], reg_mem_l,     WB_Fmask[1], reg_wb_l, 
                          Rd_data0[1], MEM_Flags[1], MEM_Result[1], WB_Flags[1], WB_Result[1]);
      out0[2] = BYPASS_F (             MEM_Fmask[2], reg_mem_l,     WB_Fmask[2], reg_wb_l, 
                          Rd_data0[2], MEM_Flags[2], MEM_Result[2], WB_Flags[2], WB_Result[2]);
      out0[3] = BYPASS_F (             MEM_Fmask[3], reg_mem_l,     WB_Fmask[3], reg_wb_l, 
                          Rd_data0[3], MEM_Flags[3], MEM_Result[3], WB_Flags[3], WB_Result[3]);
      out0[4] = BYPASS_F (             MEM_Fmask[4], reg_mem_l,     WB_Fmask[4], reg_wb_l, 
                          Rd_data0[4], MEM_Flags[4], MEM_Result[4], WB_Flags[4], WB_Result[4]);
      out0[5] = BYPASS_F (             MEM_Fmask[5], reg_mem_l,     WB_Fmask[5], reg_wb_l, 
                          Rd_data0[5], MEM_Flags[5], MEM_Result[5], WB_Flags[5], WB_Result[5]);
      out0[6] = BYPASS_F (             MEM_Fmask[6], reg_mem_l,     WB_Fmask[6], reg_wb_l, 
                          Rd_data0[6], MEM_Flags[6], MEM_Result[6], WB_Flags[6], WB_Result[6]);
      out0[7] = BYPASS_F (             MEM_Fmask[7], reg_mem_l,     WB_Fmask[7], reg_wb_l, 
                          Rd_data0[7], MEM_Flags[7], MEM_Result[7], WB_Flags[7], WB_Result[7]);
    end
  else
    begin
      out0[7:0] = BYPASS_L(reg0_exe_l,    reg_mem_l,       reg_mem_h,        reg_wb_l,       reg_wb_h, 
                           Rd_data0[7:0], MEM_Result[7:0], MEM_Result[15:8], WB_Result[7:0], WB_Result[15:8]);
    end
    
  if(reg1_exe_l == rF)
    begin
      out1[0] = BYPASS_F (             MEM_Fmask[0], reg_mem_l,     WB_Fmask[0], reg_wb_l, 
                          Rd_data1[0], MEM_Flags[0], MEM_Result[0], WB_Flags[0], WB_Result[0]);
      out1[1] = BYPASS_F (             MEM_Fmask[1], reg_mem_l,     WB_Fmask[1], reg_wb_l, 
                          Rd_data1[1], MEM_Flags[1], MEM_Result[1], WB_Flags[1], WB_Result[1]);
      out1[2] = BYPASS_F (             MEM_Fmask[2], reg_mem_l,     WB_Fmask[2], reg_wb_l, 
                          Rd_data1[2], MEM_Flags[2], MEM_Result[2], WB_Flags[2], WB_Result[2]);
      out1[3] = BYPASS_F (             MEM_Fmask[3], reg_mem_l,     WB_Fmask[3], reg_wb_l, 
                          Rd_data1[3], MEM_Flags[3], MEM_Result[3], WB_Flags[3], WB_Result[3]);
      out1[4] = BYPASS_F (             MEM_Fmask[4], reg_mem_l,     WB_Fmask[4], reg_wb_l, 
                          Rd_data1[4], MEM_Flags[4], MEM_Result[4], WB_Flags[4], WB_Result[4]);
      out1[5] = BYPASS_F (             MEM_Fmask[5], reg_mem_l,     WB_Fmask[5], reg_wb_l, 
                          Rd_data1[5], MEM_Flags[5], MEM_Result[5], WB_Flags[5], WB_Result[5]);
      out1[6] = BYPASS_F (             MEM_Fmask[6], reg_mem_l,     WB_Fmask[6], reg_wb_l, 
                          Rd_data1[6], MEM_Flags[6], MEM_Result[6], WB_Flags[6], WB_Result[6]);
      out1[7] = BYPASS_F (             MEM_Fmask[7], reg_mem_l,     WB_Fmask[7], reg_wb_l, 
                          Rd_data1[7], MEM_Flags[7], MEM_Result[7], WB_Flags[7], WB_Result[7]);
    end
  else
    begin
      out1[7:0] = BYPASS_L(reg1_exe_l,    reg_mem_l,       reg_mem_h,        reg_wb_l,       reg_wb_h, 
                           Rd_data1[7:0], MEM_Result[7:0], MEM_Result[15:8], WB_Result[7:0], WB_Result[15:8]);
    end

   /* high portion bypass */
   out0[15:8] = BYPASS_H(reg0_exe_h,    reg_mem_l,       reg_mem_h,        reg_wb_l,       reg_wb_h, 
                        Rd_data0[15:8], MEM_Result[7:0], MEM_Result[15:8], WB_Result[7:0], WB_Result[15:8]);
   out1[15:8] = BYPASS_H(reg1_exe_h,    reg_mem_l,       reg_mem_h,        reg_wb_l,       reg_wb_h, 
                        Rd_data1[15:8], MEM_Result[7:0], MEM_Result[15:8], WB_Result[7:0], WB_Result[15:8]);
    
end

// output module. do sign-extension / 0 padding 
always@(Rd0_id or out0 or Rd1_id or out1)
begin
  if(Rd0_id == rR0)
    Src0[7:0] = 8'b0;
  else
    Src0[7:0] = out0[7:0];
    
  if(Rd1_id == rR0)
    Src1[7:0] = 8'b0;
  else
    Src1[7:0] = out1[7:0];

  if(Rd0_id[4] == 1'b0)	// 8 bit, sign extension
    Src0[15:8] = {Src0[7],Src0[7],Src0[7],Src0[7],Src0[7],Src0[7],Src0[7],Src0[7]};
  else
    Src0[15:8] = out0[15:8];
    
  if(Rd1_id[4] == 1'b0)	// 8 bit, sign extension
    Src1[15:8] = {Src1[7],Src1[7],Src1[7],Src1[7],Src1[7],Src1[7],Src1[7],Src1[7]};
  else
    Src1[15:8] = out1[15:8];
end
    
endmodule
   
