/////////////////////////////////////////////////////
// misc.v
// includes memory operation control signal block and
// parity correction module for IN instruction
//
// 6bit MEMctrl is defined as follows:
//
// all signals are active-high
// 0: goes to paging  handler (others:1 / mem write:0)
// 1: Rd  
// 2: IORQ
// 3: result mux control 1: ld/in 0: others
// 4: MREQ
// 5: parity check / F correction enable for IN inst
// 6: Wr: 
//
// Dec, 2002
// Written by ikim
/////////////////////////////////////////////////////

module memstage_ctrl(MEMctrl, opcode, flush1);
input [5:0] opcode;
output [6:0] MEMctrl;
input flush1;

// NOV26 ikim
// the added flush signal so that a combined case like
// interrupt + paging doesn't flush the pipeline twice.

reg [6:0] MEMctrl;

`include "uISA.def.v"

always@(opcode or flush1)
begin
  case(opcode)
    LD_op:
      MEMctrl = 7'b0011011;
    ST_op:
      MEMctrl = {6'b101000, flush1}; // NOV26 ikim: do not detect paging if this was flushed already
    IN_op:
      MEMctrl = 7'b0101111;
    OUT_op:
      MEMctrl = 7'b1000101;
    default:
      MEMctrl = 7'b0000000;
  endcase
end

endmodule


/////////////////////////////////////////////////////
// parity_F_correction module
/////////////////////////////////////////////////////
module parity_F_correction (Flag_out, Flag_in, Data_in, enable);
input [7:0] Flag_in, Data_in;
input enable;
output [7:0] Flag_out;

reg [7:0] Flag_out;

always@(Flag_in or Data_in or enable)
begin
  if(enable == 1'b0)
    Flag_out = Flag_in;
  else
    begin
      Flag_out[7] = Data_in[7];		// S
      Flag_out[6] = (Data_in == 8'b0 ? 1'b1 : 1'b0); // Z
      Flag_out[5] = Flag_in[5];
      Flag_out[4] = 1'b0;						// H
      Flag_out[3] = Flag_in[3];
      Flag_out[2] = ~(((Data_in[0] ^ Data_in[1]) ^ (Data_in[2] ^ Data_in[3])) 
                     ^ ((Data_in[4] ^ Data_in[5]) ^ (Data_in[6] ^ Data_in[7]))); // 1 if even parity
      Flag_out[1] = 1'b0;						// N
      Flag_out[0] = Flag_in[0];					// C, not affected
    end
end

endmodule

