/////////////////////////////////////////////////
// dep_check.v
//
// Creates a bubble when mem - alu structural
// hazards are detected
//
// Written by ikim
/////////////////////////////////////////////////
module dep_check(EXE_opcode, EXE_Wr_id, EXE_Fmask, Rd0_id, Rd1_id, bubble);
input [5:0] EXE_opcode;
input [4:0] EXE_Wr_id, Rd0_id, Rd1_id;
input [7:0] EXE_Fmask;
output bubble;

reg bubble;

`include "uISA.def.v"

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

function REG_ALIASED_L;
input [4:0] TARGETID_L;
input [4:0] SRCID_L;
input [4:0] SRCID_H;
input [7:0] FMASK;
begin
  case(TARGETID_L)
    rR0:
      REG_ALIASED_L = 1'b0;
    rF:
      REG_ALIASED_L = (FMASK != 8'b0);
    default:
      REG_ALIASED_L = (TARGETID_L == SRCID_L) || (TARGETID_L == SRCID_H);
  endcase
end
endfunction

function REG_ALIASED_H;
input [4:0] TARGETID_H;
input [4:0] SRCID_L;
input [4:0] SRCID_H;
begin
  if(TARGETID_H == rR0)
    REG_ALIASED_H = 1'b0;
  else
    REG_ALIASED_H = (TARGETID_H == SRCID_L) || (TARGETID_H == SRCID_H);
end
endfunction
  
function REG_ALIASED;
input [4:0] TARGETID;
input [4:0] SRCID;
input [7:0] FMASK;
begin
  REG_ALIASED = REG_ALIASED_L(CONV_REG_L(TARGETID), CONV_REG_L(SRCID), CONV_REG_H(SRCID), FMASK) ||
                REG_ALIASED_H(CONV_REG_H(TARGETID), CONV_REG_L(SRCID), CONV_REG_H(SRCID));
end
endfunction

always@(EXE_opcode or EXE_Wr_id or EXE_Fmask or Rd0_id or Rd1_id)
begin
  if((EXE_opcode != LD_op) && (EXE_opcode != IN_op))
    bubble <= 1'b0;
  else
    begin
      if((REG_ALIASED(Rd0_id, EXE_Wr_id, EXE_Fmask) == 1'b1) 
         || (REG_ALIASED(Rd1_id, EXE_Wr_id, EXE_Fmask) == 1'b1))
        bubble <= 1'b1;
      else
        bubble <= 1'b0;
    end
end

endmodule
