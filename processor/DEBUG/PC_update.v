// ikim modified NOV24
// archPC port has been added but it wouldn't be used in the core design
// only for debug purpose
module PC_update (CLK, RST, PC_disp, archPC, next_archPC, targetPC, PCupdate, pipe_stall) ;

input CLK ;
input RST ;
input [2:0] PC_disp ;
input [15:0] targetPC ;
input PCupdate ;
input pipe_stall ;
output [15:0] archPC ;
output [15:0] next_archPC;
reg [15:0] archPC;
reg [15:0] next_archPC;

// synchronous update to archPC
always@(posedge CLK)
begin
  if(RST)
    begin
      archPC<=16'b0000_0000_0000_0000;    
    end
  else
    begin
      if(pipe_stall)
        archPC<=archPC; // do not update PC
      else
        archPC<=next_archPC;
    end
end

always@(archPC or PC_disp or targetPC or PCupdate)
begin
  if(PCupdate == 1'b1)
    // taken PC
    next_archPC <= targetPC;
  else
    // sequential pc
    next_archPC <={13'b0000_0000_0000_0,PC_disp[2:0]}+archPC;
end

endmodule 
