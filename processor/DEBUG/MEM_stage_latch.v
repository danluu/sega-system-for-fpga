//
// MEM_stage_latch
// 
// Written by: Clement Luk
// Date: 11//7/2002
//
// Function: To hold the data after the MEM stage.
//           Everything is positive edge trigger
//           and stall overrides flush.
//  
// INPUT
//
// CLK
// RST -- active high RST
// [4:0] Wr_id_in
// [7:0] Fmask_in
// [15:0] Result_in
// [7:0] Flags_in 
// stall
// 
// OUTPUT
// 
// [4:0] Wr_id_out
// [7:0] Fmask_out
// [15:0] Result
// [7:0] Flags_out 
//

module MEM_stage_latch(CLK,RST,
                       Wr_id_in,Fmask_in,Result_in,
                       Flags_in,stall,
                       Wr_id_out,Fmask_out,Result_out,Flags_out
                      // debug
                      ,DEBUG_uop, DEBUG_uop_out, DEBUG_seqNPC, DEBUG_seqNPC_out, DEBUG_taken, DEBUG_taken_out
                      ,DEBUG_addr, DEBUG_addr_out, DEBUG_rdata, DEBUG_rdata_out, DEBUG_wdata, DEBUG_wdata_out
);

input CLK,RST;
input [4:0] Wr_id_in;
input [7:0] Fmask_in;
input [15:0] Result_in;
input [7:0] Flags_in;
input stall;

output [4:0] Wr_id_out;
output [7:0] Fmask_out;
output [15:0] Result_out;
output [7:0] Flags_out;

reg [4:0] Wr_id_out;
reg [7:0] Fmask_out;
reg [15:0] Result_out;
reg [7:0] Flags_out;

// debug
input [38:0] DEBUG_uop;
output [38:0] DEBUG_uop_out;
reg [38:0] DEBUG_uop_out;
input [15:0] DEBUG_seqNPC;
output [15:0] DEBUG_seqNPC_out;
reg [15:0] DEBUG_seqNPC_out;
input DEBUG_taken;
output DEBUG_taken_out;
reg DEBUG_taken_out;
input [15:0] DEBUG_addr;
output[15:0] DEBUG_addr_out;
reg [15:0] DEBUG_addr_out;
input [7:0] DEBUG_rdata, DEBUG_wdata;
output [7:0] DEBUG_rdata_out, DEBUG_wdata_out;
reg [7:0] DEBUG_rdata_out, DEBUG_wdata_out;

  always@(posedge CLK)
  begin 
    if (RST == 1'b1)
    begin
      Wr_id_out <= 4'b0000;
      Fmask_out <= 8'b00000000;
      Result_out <= 16'b0000000000000000;
      Flags_out <= 8'b00000000;
      // debug
      DEBUG_uop_out <= 39'b0;
      DEBUG_seqNPC_out <= 16'b0;
      DEBUG_taken_out <= 1'b0;
      DEBUG_addr_out <= 16'b0;
      DEBUG_rdata_out <= 8'b0;
      DEBUG_wdata_out <= 8'b0;
    end
    else
      if (stall == 1'b1)
      begin
        Wr_id_out <= Wr_id_out;
        Fmask_out <= Fmask_out;
        Result_out <= Result_out;
        Flags_out <= Flags_out;
        // debug
        DEBUG_uop_out <= DEBUG_uop_out;
        DEBUG_seqNPC_out <= DEBUG_seqNPC_out;
        DEBUG_taken_out <= DEBUG_taken_out;
        DEBUG_addr_out <= DEBUG_addr_out;
        DEBUG_rdata_out <= DEBUG_rdata_out;
        DEBUG_wdata_out <= DEBUG_wdata_out;
      end
    else
      if (stall == 1'b0)
      begin
        Wr_id_out <= Wr_id_in;
        Fmask_out <= Fmask_in;
        Result_out <= Result_in;
        Flags_out <= Flags_in;
        // debug
        DEBUG_uop_out <= DEBUG_uop;
        DEBUG_seqNPC_out <= DEBUG_seqNPC;
        DEBUG_taken_out <= DEBUG_taken;
        DEBUG_addr_out <= DEBUG_addr;
        DEBUG_rdata_out <= DEBUG_rdata;
        DEBUG_wdata_out <= DEBUG_wdata;
      end
  end
 

endmodule 
