module uop_queue (CLK, RST, flush, IN_uop0, IN_uop1, IN_uop2, IN_uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3, pipe_stall, OUT_uop, Q_full) ;

input CLK ;
input RST ;
input flush ;
input [38:0] IN_uop0 ;
input [38:0] IN_uop1 ;
input [38:0] IN_uop2 ;
input [38:0] IN_uop3 ;
input WR_EN0 ;
input WR_EN1 ;
input WR_EN2 ;
input WR_EN3 ;
input pipe_stall ;
output [38:0] OUT_uop ;
output Q_full ;

reg [38:0] OUT_uop;
reg RD_EN0, RD_EN1, RD_EN2, RD_EN3;

wire [38:0] DOUT0, DOUT1, DOUT2, DOUT3; // output from each queue
wire FULL0, FULL1, FULL2, FULL3;
wire global_EMPTY, EMPTY0, EMPTY1, EMPTY2, EMPTY3;
wire EOI0, EOI1, EOI2, EOI3;
assign Q_full = FULL0 | FULL1 | FULL2 | FULL3;
assign global_EMPTY = EMPTY0 & EMPTY1 & EMPTY2 & EMPTY3;
assign EOI0 = DOUT0[27];
assign EOI1 = DOUT1[27];
assign EOI2 = DOUT2[27];
assign EOI3 = DOUT3[27];

reg [2:0] state, next_state;
parameter S_empty = 3'b100, S_emit0 = 3'b000, S_emit1 = 3'b001, S_emit2 = 3'b010, S_emit3 = 3'b011;
parameter NOP = 39'b000_0000_0000_1000_0000_0000_0000_0000_0000_0000;

// output module
always@(state or DOUT0 or DOUT1 or DOUT2 or DOUT3)
begin
  case(state)
    S_empty: OUT_uop <= NOP;
    S_emit0: OUT_uop <= DOUT0;
    S_emit1: OUT_uop <= DOUT1;
    S_emit2: OUT_uop <= DOUT2;
    S_emit3: OUT_uop <= DOUT3;
    default: OUT_uop <= 39'bz;  // error case
  endcase
end

// synchronous state transition
always@(posedge CLK)
begin
  if(RST)
    begin
      state <= S_empty;
    end
  else if(flush)
    begin
      state <= S_empty;
    end
  else
    begin
      state <= next_state;
    end
end

// next state generatioin
always@(state or global_EMPTY or EOI0 or EOI1 or EOI2 or EOI3 or pipe_stall)
begin
  // default outputs
  RD_EN0 <= 1'b0;
  RD_EN1 <= 1'b0;
  RD_EN2 <= 1'b0;
  RD_EN3 <= 1'b0;
  next_state <= 3'bz;  // error case default
  
  case(state)
    S_empty:
      begin
        if(!global_EMPTY && !pipe_stall)
          begin
            RD_EN0 <= 1'b1;
            next_state <= S_emit0;
         end 
       else
         begin
           next_state <= S_empty;
         end
      end
           
    S_emit0:
      begin
        if(pipe_stall)
          begin
            next_state <= S_emit0;
          end
        else
          begin
            case({global_EMPTY, EOI0})
              2'b00:
                begin
                  next_state <= S_emit1;
                  RD_EN1 <= 1'b1;
                end
              2'b01:
                begin
                  next_state <= S_emit0;
                  RD_EN0 <= 1'b1;
                end
              2'b10:
                begin
                  next_state <= 3'bz;  // error
                end
              2'b11:
                begin
                  next_state <= S_empty;
                end
            endcase
          end
      end
      
    S_emit1:
      begin
        if(pipe_stall)
          begin
            next_state <= S_emit1;
          end
        else
          begin
            case({global_EMPTY, EOI1})
              2'b00:
                begin
                  next_state <= S_emit2;
                  RD_EN2 <= 1'b1;
                end
              2'b01:
                begin
                  next_state <= S_emit0;
                  RD_EN0 <= 1'b1;
                end
              2'b10:
                begin
                  next_state <= 3'bz;  // error
                end
              2'b11:
                begin
                  next_state <= S_empty;
                end
            endcase
          end
      end
      
    S_emit2:
      begin
        if(pipe_stall)
          begin
            next_state <= S_emit2;
          end
        else
          begin
            case({global_EMPTY, EOI2})
              2'b00:
                begin
                  next_state <= S_emit3;
                  RD_EN3 <= 1'b1;
                end
              2'b01:
                begin
                  next_state <= S_emit0;
                  RD_EN0 <= 1'b1;
                end
              2'b10:
                begin
                  next_state <= 3'bz;  // error
                end
              2'b11:
                begin
                  next_state <= S_empty;
                end
            endcase
          end
      end
      
    S_emit3:
      begin
        if(pipe_stall)
          begin
            next_state <= S_emit3;
          end
        else
          begin
            case({global_EMPTY, EOI3})
              2'b00:
                begin
                  next_state <= S_emit0;
                  RD_EN0 <= 1'b1;
                end
              2'b01:
                begin
                  next_state <= S_emit0;
                  RD_EN0 <= 1'b1;
                end
              2'b10:
                begin
                  next_state <= 3'bz;  // error
                end
              2'b11:
                begin
                  next_state <= S_empty;
                end
            endcase
          end
      end
      
    default: begin end // error case
  endcase
end

fifo Q0(.CLK(CLK),.SINIT(RST|flush),.DIN(IN_uop0),.WR_EN(WR_EN0 & ~Q_full),.RD_EN(RD_EN0),.DOUT(DOUT0),.FULL(FULL0),.EMPTY(EMPTY0));
fifo Q1(.CLK(CLK),.SINIT(RST|flush),.DIN(IN_uop1),.WR_EN(WR_EN1 & ~Q_full),.RD_EN(RD_EN1),.DOUT(DOUT1),.FULL(FULL1),.EMPTY(EMPTY1));
fifo Q2(.CLK(CLK),.SINIT(RST|flush),.DIN(IN_uop2),.WR_EN(WR_EN2 & ~Q_full),.RD_EN(RD_EN2),.DOUT(DOUT2),.FULL(FULL2),.EMPTY(EMPTY2));
fifo Q3(.CLK(CLK),.SINIT(RST|flush),.DIN(IN_uop3),.WR_EN(WR_EN3 & ~Q_full),.RD_EN(RD_EN3),.DOUT(DOUT3),.FULL(FULL3),.EMPTY(EMPTY3));

endmodule 
