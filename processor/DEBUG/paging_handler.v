module paging_handler(CLK, RST, MREQ, addr, Rd_Wr, flush0, paging_RQ);
input CLK, RST, MREQ, Rd_Wr, flush0;
input [15:0] addr;
output paging_RQ;

wire paging_RQ;

reg Flipflop, nFlipflop;
wire paging_condition;
assign paging_condition = (addr[15:2] == 14'b11111111111111) && (MREQ == 1'b1) && (Rd_Wr == 1'b0);

always@(posedge CLK)
begin
  if(RST)
    Flipflop <= 0;
  else
    Flipflop <= nFlipflop;
end

// next state generation
always@(paging_condition or flush0 or Flipflop)
begin
  case({paging_condition, flush0})
    2'b00:
      nFlipflop <= Flipflop;
    2'b01:
      nFlipflop <= 1'b0;
    2'b10:
      nFlipflop <= 1'b1;
    2'b11:
      nFlipflop <= 1'b0;
  endcase
end

// paging_RQ (real output) generation
assign paging_RQ = ((Flipflop == 1'b0) && (paging_condition == 1'b1)) || (Flipflop == 1'b1);
endmodule
