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
                       Wr_id_out,Fmask_out,Result_out,Flags_out);

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

  always@(posedge CLK)
  begin 
    if (RST == 1'b1)
    begin
      Wr_id_out <= 4'b0000;
      Fmask_out <= 8'b00000000;
      Result_out <= 16'b0000000000000000;
      Flags_out <= 8'b00000000;
    end
    else
      if (stall == 1'b1)
      begin
        Wr_id_out <= Wr_id_out;
        Fmask_out <= Fmask_out;
        Result_out <= Result_out;
        Flags_out <= Flags_out;
      end
    else
      if (stall == 1'b0)
      begin
        Wr_id_out <= Wr_id_in;
        Fmask_out <= Fmask_in;
        Result_out <= Result_in;
        Flags_out <= Flags_in;
      end
  end
 

endmodule 
