//
// RF_stage_latch
// 
// Written by: Clement Luk
// Date: 11//7/2002
 
// Function: To hold the data after the RF stage.
//           Everything is positive edge trigger
//           and stall overrides flush.
//  
// INPUT
//
// CLK  -- clock 
// RST  -- active high RST 
// [5:0] opcodereg;
// [4:0] Wr_id_in;
// [7:0] Fmask_in;
// [15:0] IMM_in;
// EOI_in;
// [15:0] Rd_data0_in;
// [4:0] Rd0_id_in;
// [15:0] Rd_data1_in;
// [4:0] Rd1_id_in;
// [15:0] seqNPC_in;
// flush,stall;
//
// OUTPUT
//
// [5:0] opcode_out;
// [4:0] Wr_id_out;
// [7:0] Fmask_out;
// [15:0] IMM_out;
// EOI_out;
// [15:0] Rd_data0_out;
// [4:0] Rd0_id_out;
// [15:0] Rd_data1_out;
// [4:0] Rd1_id_out;
// [15:0] seqNPC_out;

module RF_stage_latch(CLK,RST,
                      opcode_in,Wr_id_in,Fmask_in,IMM_in,
                      EOI_in,Rd_data0_in,Rd0_id_in,
                      Rd_data1_in,Rd1_id_in,seqNPC_in,
                      flush,stall,
                      opcode_out,Wr_id_out,Fmask_out,IMM_out,
                      EOI_out,Rd_data0_out,Rd0_id_out,
                      Rd_data1_out,Rd1_id_out,seqNPC_out,
									 // extra ports for debug 
                      DEBUG_uop, DEBUG_uop_out
);

input CLK,RST;
input [5:0] opcode_in;
input [4:0] Wr_id_in;
input [7:0] Fmask_in;
input [15:0] IMM_in;
input EOI_in;
input [15:0] Rd_data0_in;
input [4:0] Rd0_id_in;
input [15:0] Rd_data1_in;
input [4:0] Rd1_id_in;
input [15:0] seqNPC_in;
input flush,stall;

output  [5:0] opcode_out;
output [4:0] Wr_id_out;
output [7:0] Fmask_out;
output [15:0] IMM_out;
output EOI_out;
output [15:0] Rd_data0_out;
output [4:0] Rd0_id_out;
output [15:0] Rd_data1_out;
output [4:0] Rd1_id_out;
output [15:0] seqNPC_out;

// debug
input [38:0] DEBUG_uop;
output [38:0] DEBUG_uop_out;
reg [38:0] DEBUG_uop_out;

reg [5:0] opcode_out;
reg [4:0] Wr_id_out;
reg [7:0] Fmask_out;
reg [15:0] IMM_out;
reg EOI_out;
reg [15:0] Rd_data0_out;
reg [4:0] Rd0_id_out;
reg [15:0] Rd_data1_out;
reg [4:0] Rd1_id_out;
reg [15:0] seqNPC_out;


  always@(posedge CLK)
  begin
    if (RST == 1'b1)
    begin
      opcode_out <= 6'b000000;
      Wr_id_out <= 5'b00000;
      Fmask_out <= 8'b00000000;
      IMM_out <= 16'b0000000000000000;
      EOI_out <= 1'b0;
      Rd_data0_out <= 16'b0000000000000000;
      Rd0_id_out <= 5'b00000;
      Rd_data1_out <= 16'b0000000000000000;
      Rd1_id_out <= 5'b00000;
      seqNPC_out <= 16'b0000000000000000;

      // debug
      DEBUG_uop_out <= 39'b0;

    end//if RST=0
    else
      if (stall == 1'b1) // stall overrides flush
      begin
        opcode_out <= opcode_out;
        Wr_id_out <= Wr_id_out;
        Fmask_out <= Fmask_out;
        IMM_out <= IMM_out;
        EOI_out <= EOI_out; 
        Rd_data0_out <= Rd_data0_out;
        Rd0_id_out <= Rd0_id_out;
        Rd_data1_out <= Rd_data1_out;
        Rd1_id_out <= Rd1_id_out;
        seqNPC_out <= seqNPC_out;
        // debug
        DEBUG_uop_out <= DEBUG_uop_out;
      end//if stall=0
    else 
      if (flush == 1'b1)
      begin
        opcode_out <= 6'b000000;
        Wr_id_out <= 5'b00000;
        Fmask_out <= 8'b00000000;
        IMM_out <= 16'b0000000000000000;
        EOI_out <= 1'b0;
        Rd_data0_out <= 16'b0000000000000000;
        Rd0_id_out <= 5'b00000;
        Rd_data1_out <= 16'b0000000000000000;
        Rd1_id_out <= 5'b00000;
        seqNPC_out <= 16'b0000000000000000;
        // debug
        DEBUG_uop_out <= 39'b0;
      end//flush, stall =0
    else
        begin // we update here 
        opcode_out <= opcode_in;
        Wr_id_out <= Wr_id_in;
        Fmask_out <= Fmask_in;
        IMM_out <= IMM_in;
        EOI_out <= EOI_in; 
        Rd_data0_out <= Rd_data0_in;
        Rd0_id_out <= Rd0_id_in;
        Rd_data1_out <= Rd_data1_in;
        Rd1_id_out <= Rd1_id_in;
        seqNPC_out <= seqNPC_in;
        // debug
        DEBUG_uop_out <= DEBUG_uop;
      end 
  end

endmodule 



