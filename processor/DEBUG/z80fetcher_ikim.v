module z80fetcher (CLK, RST, flush, I_wait, z80dec_stall, targetPC, MREQ, I_Addr) ;

input CLK ;
input RST ;
input flush ;
input I_wait ;
input z80dec_stall ;
input [15:0] targetPC ;
output MREQ ;
output [15:0] I_Addr ;

reg [15:0] I_Addr;
reg MREQ;
reg [2:0] warming_up;

always@(posedge CLK)
begin
  if(RST==1)
  begin
    I_Addr<=16'b1111_1111_1111_1111;
    warming_up<=3'b000;
    MREQ<=1'b0;
  end
  else 
  begin
    if(warming_up != 3'b111)
      begin
        warming_up<=warming_up+1;
        MREQ<=1'b0;
        I_Addr<=I_Addr;
      end
    else
    if(flush==0)
    begin
      if((I_wait==1) || (z80dec_stall==1))
      begin
        I_Addr<=I_Addr;
        MREQ<=MREQ;
      end    
      else
      begin
        I_Addr<=I_Addr+1;
        MREQ<=1'b1;
      end
    end
    else /* flush condition */
    begin
      I_Addr<=targetPC;
      MREQ<=1'b1;
    end
  end
end

endmodule 
