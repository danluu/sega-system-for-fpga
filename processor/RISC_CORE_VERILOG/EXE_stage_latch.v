//
// EXE_stage_latch
//
// Written by: Clement Luk
// Date: 11//7/2002
//
// Function: To hold the data after the EXE stage.
//           Everything is positive edge trigger
//           and stall overrides flush.
//  
// INPUT
// 
// CLK
// RST -- active high RST
// [4:0] Wr_id_in
// [7:0] Fmask_in
// [5:0] MEMctrl_in
// [7:0] Flags_in 
// [15:0] Result_in
// [15:0] Src1_in
// [15:0] seqNPC_in
// EOI_in
// flush
// stall

// OUTPUT
//
// [4:0] Wr_id_out
// [7:0] Fmask_out
// [6:0] MEMctrl_out
// [7:0] Flags_out 
// [15:0] Result_out
// [15:0] Src1_out
// [15:0] seqNPC_out
// EOI_out


module EXE_stage_latch(CLK,RST,
                       Wr_id_in,Fmask_in,MEMctrl_in,
                       Flags_in,Result_in,Src1_in,
                       seqNPC_in,EOI_in, flush,stall,
                       Wr_id_out,Fmask_out,MEMctrl_out,
                       Flags_out,Result_out,Src1_out,
                       EOI_out,seqNPC_out);

input CLK,RST;
input [4:0] Wr_id_in;
input [7:0] Fmask_in;
input [6:0] MEMctrl_in;
input [7:0] Flags_in; 
input [15:0] Result_in;
input [15:0] Src1_in;
input [15:0] seqNPC_in;
input EOI_in, flush,stall;

output [4:0] Wr_id_out;
output [7:0] Fmask_out;
output [6:0] MEMctrl_out;
output [7:0] Flags_out; 
output [15:0] Result_out;
output [15:0] Src1_out;
output [15:0] seqNPC_out;
output EOI_out;

reg [4:0] Wr_id_out;
reg [7:0] Fmask_out;
reg [6:0] MEMctrl_out;
reg [7:0] Flags_out; 
reg [15:0] Result_out;
reg [15:0] Src1_out;
reg [15:0] seqNPC_out;
reg EOI_out;

  always@(posedge CLK)
  begin
    if (RST == 1'b1)
    begin
      Wr_id_out <= 5'b00000;
      Fmask_out <= 8'b00000000;
      MEMctrl_out <= 7'b000000;
      Flags_out <= 8'b00000000;
      Result_out <= 16'b0000000000000000;
      Src1_out <= 16'b0000000000000000;
      seqNPC_out <= 16'b0000000000000000;
      EOI_out <= 1'b0;
    end
    else
      if (stall == 1'b1) // stall overrides flush
      begin
        Wr_id_out <= Wr_id_out;
        Fmask_out <= Fmask_out;
        MEMctrl_out <= MEMctrl_out;
        Flags_out <= Flags_out;
        Result_out <= Result_out;
        Src1_out <= Src1_out;
        seqNPC_out <= seqNPC_out;   
        EOI_out <= EOI_out;
      end
    else
      if ((flush == 1'b1)&&
          (stall == 1'b0))
      begin
        Wr_id_out <= 5'b00000;
        Fmask_out <= 8'b00000000;
        MEMctrl_out <= 7'b000000;
        Flags_out <= 8'b00000000;
        Result_out <= 16'b0000000000000000;
        Src1_out <= 16'b0000000000000000;
        seqNPC_out <= 16'b0000000000000000;
        EOI_out <= 1'b0;
      end
    else
      if((stall == 1'b0)&&
         (flush == 1'b0)) // we update here 
      begin
        Wr_id_out <= Wr_id_in;
        Fmask_out <= Fmask_in;
        MEMctrl_out <= MEMctrl_in;
        Flags_out <= Flags_in;
        Result_out <= Result_in;
        Src1_out <= Src1_in;
        seqNPC_out <= seqNPC_in;   
        EOI_out <= EOI_in;
      end
  end

endmodule 
