module interrupt_handler(CLK, RST, extern_INT, extern_NMI, intern_INT, intern_NMI, interrupt_RQ, flush0,
                         IFF1, IFF2, opcode, mem_pipe_stall);
input CLK, RST, extern_INT, extern_NMI, flush0;
input [5:0] opcode;
input mem_pipe_stall;
output intern_INT, intern_NMI, interrupt_RQ, IFF1, IFF2;

wire intern_INT, intern_NMI, interrupt_RQ;
wire IFF1, IFF2;

parameter stby_s = 2'b00, INT_s = 2'b01, NMI_s = 2'b10; 
reg [1:0]state, n_state;

reg [1:0] IFF1_state, IFF2_state, n_IFF1_state, n_IFF2_state;

`include "uISA.def.v"

// signal outputs
assign intern_INT = (state == INT_s) && (n_state == stby_s);
assign intern_NMI = (state == NMI_s) && (n_state == stby_s);
assign interrupt_RQ = (state == INT_s) || (state == NMI_s);
assign IFF1 = IFF1_state[1];
assign IFF2 = IFF2_state[1];

always@(posedge CLK)
begin
  if(RST == 1'b1)
    begin
      state <= stby_s;
      IFF1_state <= 2'b0;
      IFF2_state <= 2'b0;
    end
  else if(mem_pipe_stall == 1'b1)
    begin
      state <= state;
      IFF1_state <= IFF1_state;
      IFF2_state <= IFF2_state;
    end
  else
    begin
      state <= n_state;
      IFF1_state <= n_IFF1_state;
      IFF2_state <= n_IFF2_state;
    end
end

// IFF next state generation
always@(IFF1_state or IFF2_state or extern_NMI or extern_INT or opcode)
begin
  if(opcode == IFF2IFF1_op)
    n_IFF1_state <= IFF2_state;
  else
  case(IFF1_state)
    2'b00:
      if(opcode == EI_op)
        n_IFF1_state <= 2'b01;
      else
        n_IFF1_state <= IFF1_state;
    2'b01:
      if(opcode != ADD_op)
        n_IFF1_state <= 2'b10;
      else
        n_IFF1_state <= IFF1_state;
    2'b10:
      if((opcode == DI_op) || (extern_NMI == 1'b1) || (extern_INT == 1'b1))
        n_IFF1_state <= 2'b00;
      else
        n_IFF1_state <= IFF1_state;
    default:
      n_IFF1_state <= 2'b00;
  endcase
  
  case(IFF2_state)
    2'b00:
      if(opcode == EI_op)
        n_IFF2_state <= 2'b01;
      else
        n_IFF2_state <= IFF2_state;
    2'b01:
      if(opcode != ADD_op)
        n_IFF2_state <= 2'b10;
      else
        n_IFF2_state <= IFF2_state;
    2'b10:
      if((opcode == DI_op) || ((extern_INT == 1'b1) && (extern_NMI == 1'b0)))
        n_IFF2_state <= 2'b00;
      else
        n_IFF2_state <= IFF2_state;
    default:
      n_IFF2_state <= 2'b00;
  endcase
end

// module next state generator
always@(IFF1 or extern_NMI or extern_INT or flush0 or state or opcode)
begin
  case(state)
    stby_s:
      if(opcode == IFF2IFF1_op || opcode == DI_op)
        n_state <= state;
      else if((IFF1 == 1'b1) && (extern_INT == 1'b1)) 
        n_state <= INT_s;
      else if(extern_NMI == 1'b1)
        n_state <= NMI_s;
      else
        n_state <= state;          
    INT_s:
      if(flush0 == 1'b1)
        n_state <= stby_s;
      else
        n_state <= state;
    NMI_s:
      if(flush0 == 1'b1)
        n_state <= stby_s;
      else
        n_state <= state;
    default:
      n_state <= stby_s;
  endcase
end

endmodule
