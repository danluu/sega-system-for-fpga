///////////////////////////////////////////////////////////
// xlator in translator part
///////////////////////////////////////////////////////////
module xlator (CLK, RST, flush, NMI, INT, I_word, I_word_rdy, z80_I_ID, Q_full,
               uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3,
               xlator_stall);

input CLK, RST, flush, NMI, INT, I_word_rdy, Q_full;
input [31:0] I_word;
input [7:0] z80_I_ID;
output [38:0] uop0, uop1, uop2, uop3; // uops generated
output WR_EN0, WR_EN1, WR_EN2, WR_EN3; // valid uops?
output xlator_stall;

reg [38:0] uop0, uop1, uop2, uop3; // uops generated
reg WR_EN0, WR_EN1, WR_EN2, WR_EN3; // valid uops?
reg xlator_stall;

reg [1:0] curr_state, next_state;
reg [31:0] I_word_latch;	// z80 instruction storage
reg [7:0]  I_ID_latch;	    // z80 I_ID_latch

// xlation core
wire [38:0] xlate0, xlate1, xlate2, xlate3, 
           xlate4, xlate5, xlate6, xlate7,
           xlate8, xlate9, xlate10, xlate11;
wire [11:0] xlate_valid;
wire [1:0]  num_frame;

xlate_core CORE (I_word_latch, I_ID_latch, xlate0, xlate1, xlate2, xlate3
                  , xlate4, xlate5, xlate6, xlate7, xlate8, xlate9
                  , xlate10, xlate11, xlate_valid, num_frame);

// for debug
reg xlate_outofsync;

// state definitions
parameter init_s = 2'b00, frame1_s = 2'b01, frame2_s = 2'b10, frame3_s = 2'b11;

// int/nmi handler def
parameter INT_handler = 254, NMI_handler = 255;

// synchronous latch /////////////////////////////////
always@(posedge CLK)
begin
  if(RST == 1'b1)
    begin
      curr_state <= init_s;
      I_word_latch <= 32'b0;
      I_ID_latch <= 8'b0;
    end
  else if((NMI == 1'b1) || (INT == 1'b1))
    begin
      curr_state <= frame1_s;
      I_word_latch <= 32'b0;
      I_ID_latch <= ((NMI == 1'b1) ? NMI_handler : INT_handler);
    end
  else if(flush == 1'b1)
    begin
      curr_state <= init_s;
      I_word_latch<= 32'b0;
      I_ID_latch <=8'b0;
    end
  else
    begin
      if(I_word_rdy == 1'b1)
        if(next_state == frame1_s)
          if((curr_state != frame1_s) || (Q_full == 1'b0))
            begin  // latch the instruction and ID
              I_word_latch <= I_word;
              I_ID_latch <= z80_I_ID;
            end

      // advance to the next state
      curr_state <= next_state; 
    end
end

// next state generator ////////////////////////////////////
always@(I_word_rdy or Q_full or curr_state or num_frame)
begin
  // default settings
  next_state <= init_s;
  xlate_outofsync <= 1'b0;
  xlator_stall <= 1'b0;
  
  case(curr_state)
    init_s:
      begin
        if(I_word_rdy == 1'b0)
          next_state <= init_s;
        else
          next_state <= frame1_s;
      end
    frame1_s:
      begin
        if(Q_full == 1'b1)
          begin
            next_state <= frame1_s;
            xlator_stall <= 1'b1;
          end
        else if(num_frame == 2'b01)
          begin
            if(I_word_rdy == 1'b1)
              next_state <= frame1_s;
            else
              next_state <= init_s;
          end
        else
          begin
            next_state <= frame2_s;
            xlator_stall <= 1'b1;
          end
      end   
    frame2_s:
      begin
        if(Q_full == 1'b1)
          begin
            next_state <= frame2_s;
            xlator_stall <= 1'b1;
          end
        else if(num_frame == 2'b10)
          begin
            if(I_word_rdy == 1'b1)
              next_state <= frame1_s;
            else
              next_state <= init_s;
          end
        else
          begin
            next_state <= frame3_s;
            xlator_stall <= 1'b1;
          end
      end
    frame3_s:
      begin
        if(Q_full == 1'b1)
          begin
            next_state <= frame3_s;
            xlator_stall <= 1'b1;
          end
        else if(num_frame == 2'b11)
          begin
            if(I_word_rdy == 1'b1)
              next_state <= frame1_s;
            else
              next_state <= init_s;
          end
        else
          begin
            next_state <= init_s;
            xlate_outofsync <= 1'b1;
          end
      end
    default: begin end
  endcase
end

// output module. put uops and WR_ENs onto ports//////////////
always@(curr_state or xlate0 or xlate1 or xlate2
        or xlate3 or xlate4 or xlate5 or xlate6 or xlate7
        or xlate8 or xlate9 or xlate10 or xlate11 or xlate_valid)
begin
  // default output
  uop0 <= 38'b0;
  uop1 <= 38'b0;
  uop2 <= 38'b0;
  uop3 <= 38'b0;
  WR_EN0 <= 1'b0;
  WR_EN1 <= 1'b0;
  WR_EN2 <= 1'b0;
  WR_EN3 <= 1'b0;

  case(curr_state)
    init_s: begin end
    frame1_s:
      begin
        uop0 <= xlate0;
        uop1 <= xlate1;
        uop2 <= xlate2;
        uop3 <= xlate3;
        WR_EN0 <= xlate_valid[0];
        WR_EN1 <= xlate_valid[1];
        WR_EN2 <= xlate_valid[2];
        WR_EN3 <= xlate_valid[3];
      end
    frame2_s:
      begin
        uop0 <= xlate4;
        uop1 <= xlate5;
        uop2 <= xlate6;
        uop3 <= xlate7;
        WR_EN0 <= xlate_valid[4];
        WR_EN1 <= xlate_valid[5];
        WR_EN2 <= xlate_valid[6];
        WR_EN3 <= xlate_valid[7];
      end
    frame3_s:
      begin
        uop0 <= xlate8;
        uop1 <= xlate9;
        uop2 <= xlate10;
        uop3 <= xlate11;
        WR_EN0 <= xlate_valid[8];
        WR_EN1 <= xlate_valid[9];
        WR_EN2 <= xlate_valid[10];
        WR_EN3 <= xlate_valid[11];
      end
    default: begin end
  endcase
end
endmodule

///////////////////////////////////////////////////////////
// xlator_core in xlator
///////////////////////////////////////////////////////////

module xlate_core(I_word, z80_I_ID, xlate0, xlate1, xlate2, xlate3
                  , xlate4, xlate5, xlate6, xlate7, xlate8, xlate9
                  , xlate10, xlate11, xlate_valid, num_frame);

input [31:0] I_word;
input [7:0] z80_I_ID;
output [38:0] xlate0, xlate1, xlate2, xlate3, 
              xlate4, xlate5, xlate6, xlate7,
              xlate8, xlate9, xlate10, xlate11;
output [11:0] xlate_valid; // valid bit vector for instructions
output [1:0]  num_frame;


reg [38:0] xlate0, xlate1, xlate2, xlate3, 
              xlate4, xlate5, xlate6, xlate7,
              xlate8, xlate9, xlate10, xlate11;
reg [11:0] xlate_valid; // valid bit vector for instructions
reg [1:0] num_frame;

// num_frame calculation
always@(xlate_valid)
begin
  if(xlate_valid[8] == 1'b1)
    num_frame <= 2'b11;
  else if(xlate_valid[4] == 1'b1)
    num_frame <= 2'b10;
  else if(xlate_valid[0] == 1'b1)
    num_frame <= 2'b01;
  else
    num_frame <= 0;
end

// z80_I_ID definitions
//`include "..\z80_decoder\z80_I_ID.def"
`include "z80_I_ID.def"
// int/nmi handler def
parameter INT_handler = 254, NMI_handler = 255;
// uISA definitios
`include "uISA.def.v"

// helper functions ////////////////////////////////////
task XLATE_CLEAR;
inout [38:0] inst;
begin
  inst = 39'b0;
end
endtask

task XLATE_VALID_CLEAR;
begin
  xlate_valid = 12'b0;
end
endtask

task XLATE_VALID_SET;
input [3:0] num_emitted;
begin
  case(num_emitted)
    4'D0:
      xlate_valid = 12'b000000000000;
    4'D1:
      xlate_valid = 12'b000000000001;
    4'D2:
      xlate_valid = 12'b000000000011;
    4'D3:
      xlate_valid = 12'b000000000111;
    4'D4:
      xlate_valid = 12'b000000001111;
    4'D5:
      xlate_valid = 12'b000000011111;
    4'D6:
      xlate_valid = 12'b000000111111;
    4'D7:
      xlate_valid = 12'b000001111111;
    4'D8:
      xlate_valid = 12'b000011111111;
    4'D9:
      xlate_valid = 12'b000111111111;
    4'D10:
      xlate_valid = 12'b001111111111;
    4'D11:
      xlate_valid = 12'b011111111111;
    4'D12:
      xlate_valid = 12'b111111111111;
    default:
      xlate_valid = 12'b000000000000;
  endcase
end
endtask

task EMIT_PC_DISP;
inout [38:0] inst;
input [2:0] PC_disp;
begin
  inst [38:36] = PC_disp;
end
endtask

// flag setup
// SZxHxPNC
task EMIT_F_MASK;
inout [38:0] inst;
input [7:0] F_mask;
begin
  inst [35:28] = F_mask;
end
endtask

task EMIT_EOI;
inout [38:0] inst;
begin
  inst [27] = 1'b1;
end
endtask

// extract z80 reg specifier (3bit)
// the order will be 01/23/45/67
function [2:0] Z80_REG;
input [31:0] z80_I_word;
input [2:0] location;
begin
  case(location)
    0:
      Z80_REG = z80_I_word [29:27];
    1:
      Z80_REG = z80_I_word [26:24];
    2:
      Z80_REG = z80_I_word [21:19];
    3:
      Z80_REG = z80_I_word [18:16];
    4:
      Z80_REG = z80_I_word [13:11];
    5:
      Z80_REG = z80_I_word [10:8];
    6:
      Z80_REG = z80_I_word [5:3];
    7:
      Z80_REG = z80_I_word [2:0];
    default:
      Z80_REG = z80_I_word [26:24];
  endcase
end
endfunction

// extract z80 byte
function [7:0] Z80_BYTE;
input [31:0] z80_I_word;
input [1:0] byte;
begin
  case(byte)
    2'b00:
      Z80_BYTE = z80_I_word [31:24];
    2'b01:
      Z80_BYTE = z80_I_word [23:16];
    2'b10:
      Z80_BYTE = z80_I_word [15:8];
    2'b11:
      Z80_BYTE = z80_I_word [7:0];
    default: 
      Z80_BYTE = z80_I_word [31:24];
  endcase      
end
endfunction

// extract z80 left/right reg specifier (3bit)
function [2:0] Z80_REGL;
input [7:0] z80_I_byte;
begin
  Z80_REGL = z80_I_byte [5:3];
end
endfunction

function [2:0] Z80_REGR;
input [7:0] z80_I_byte;
begin
  Z80_REGR = z80_I_byte [2:0];
end
endfunction

// 8bit z80 -> uop register conversion
// be careful so that z80 reg is not 110
// (will be converted into R0)
function [4:0] REG_CONV8;
input [2:0] z80_reg;
begin
  if(z80_reg == 3'b110)
    REG_CONV8 = rR0;
  else
    REG_CONV8 = {1'b0,z80_reg,1'b1};
end
endfunction

// 16bit conversion
function [4:0] REG_CONV_CELP;
input [1:0] z80_reg;
begin
  case(z80_reg)
    2'b00: REG_CONV_CELP = rBC;
    2'b01: REG_CONV_CELP = rDE;
    2'b10: REG_CONV_CELP = rHL;
    2'b11: REG_CONV_CELP = rSP;
    default: REG_CONV_CELP = rR0;
  endcase
end
endfunction

function [4:0] REG_CONV_CELF;
input [1:0] z80_reg;
begin
  case(z80_reg)
    2'b00: REG_CONV_CELF = rBC;
    2'b01: REG_CONV_CELF = rDE;
    2'b10: REG_CONV_CELF = rHL;
    2'b11: REG_CONV_CELF = rAF;
    default: REG_CONV_CELF = rR0;
  endcase
end
endfunction

// 16bit conversion
function [4:0] REG_CONV_CEXP;
input [1:0] z80_reg;
begin
  case(z80_reg)
    2'b00: REG_CONV_CEXP = rBC;
    2'b01: REG_CONV_CEXP = rDE;
    2'b10: REG_CONV_CEXP = rIX;
    2'b11: REG_CONV_CEXP = rSP;
    default: REG_CONV_CEXP = rR0;
  endcase
end
endfunction

// 16bit conversion
function [4:0] REG_CONV_CEYP;
input [1:0] z80_reg;
begin
  case(z80_reg)
    2'b00: REG_CONV_CEYP = rBC;
    2'b01: REG_CONV_CEYP = rDE;
    2'b10: REG_CONV_CEYP = rIY;
    2'b11: REG_CONV_CEYP = rSP;
    default: REG_CONV_CEYP = rR0;
  endcase
end
endfunction

// CC conversion, returns bit position
function [2:0] Z80_CC_BPOS;
input [2:0] z80_cc;
begin
  case(z80_cc[2:1])
    2'b00: Z80_CC_BPOS = 3'b110;	// Z
    2'b01: Z80_CC_BPOS = 3'b000;	// C
    2'b10: Z80_CC_BPOS = 3'b010;	// P/V
    2'b11: Z80_CC_BPOS = 3'b111;	// S
    default: Z80_CC_BPOS = 3'b000;
  endcase
end
endfunction

// uop EMIT routines ////////////////////////////////////
task EMIT_INST_RRR;
inout [38:0] inst;
input [5:0] opcode;
input [4:0] Rd;
input [4:0] Rs;
input [4:0] Rt;
begin
  inst = {12'b000000000000,opcode,Rd,Rs,Rt,6'b000000};
end
endtask

task EMIT_INST_RRI;
inout [38:0] inst;
input [5:0] opcode;
input [4:0] Rd;
input [4:0] Rs;
input [7:0] IMM;
begin
  inst = {12'b000000000000,opcode,Rd,Rs,3'b000,IMM};
end
endtask


// IMM L/H are exchanged, according to z80 endianess
task EMIT_INST_RI;
inout [38:0] inst;
input [5:0] opcode;
input [4:0] Rd;
input [15:0] IMM;
begin
  inst = {12'b000000000000,opcode,Rd,IMM[7:0],IMM[15:8]};
end
endtask

// translation core here ////////////////////////////////////
always@(I_word or z80_I_ID)
begin
  // initial setup
  XLATE_VALID_CLEAR;
  XLATE_CLEAR(xlate0); XLATE_CLEAR(xlate1); XLATE_CLEAR(xlate2); XLATE_CLEAR(xlate3);
  XLATE_CLEAR(xlate4); XLATE_CLEAR(xlate5); XLATE_CLEAR(xlate6); XLATE_CLEAR(xlate7);
  XLATE_CLEAR(xlate8); XLATE_CLEAR(xlate9); XLATE_CLEAR(xlate10); XLATE_CLEAR(xlate11);
  case(z80_I_ID)
    NOP: ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end

	ADC_A_s_1: //A, r//////////////////////////////////////////////////
      begin
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRR(xlate1, ADD_op, rT0, rT0, REG_CONV8(I_word[26:24]));
        
        EMIT_INST_RRR(xlate2, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate2, 8'b11111111);
        EMIT_EOI     (xlate2);
      end
      
	ADC_A_s_2: //A, n//////////////////////////////////////////////////
      begin
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, I_word[23:16]);      
        
        EMIT_INST_RRR(xlate2, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate2, 8'b11111111);
        EMIT_EOI     (xlate2);
      end
      
	ADC_A_s_3: //A, (HL)//////////////////////////////////////////////////
      begin
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rHL, 0);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  
            
        EMIT_INST_RRR(xlate3, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate3, 8'b11111111);
        EMIT_EOI     (xlate3);
      end
      
	ADC_A_s_4: //A, (IX+d)//////////////////////////////////////////////////
      begin
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIX, I_word[15:8]);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  
            
        EMIT_INST_RRR(xlate3, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate3, 8'b11111111);
        EMIT_EOI     (xlate3);
      end
      
	ADC_A_s_5: //A, (IY+d) //////////////////////////////////////////////////
      begin
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIY, I_word[15:8]);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  
            
        EMIT_INST_RRR(xlate3, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate3, 8'b11111111);
        EMIT_EOI     (xlate3);
      end
      
	ADC_HL_ss: //HL<-HL+ss+CY//////////////////////////////////////////////////
      begin
        // flag problems, cannot detect transitive overflow
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rT0, REG_CONV_CELP(I_word[21:20]));
              
        EMIT_INST_RRR(xlate2, ADD16_op, rHL, rHL, rT32);
        EMIT_F_MASK  (xlate2, 8'b11111111);
        EMIT_EOI     (xlate2);
      end
      
	ADD_A_HL : //A<-A+(HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);
                
        EMIT_INST_RRR(xlate1, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        EMIT_EOI     (xlate1);
      end
      
	ADD_A_IX_d: //A<-A+(IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, Z80_BYTE(I_word, 2));
        EMIT_PC_DISP (xlate0, 3);
                
        EMIT_INST_RRR(xlate1, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        EMIT_EOI     (xlate1);
      end
      
	ADD_A_IY_d: //A<-A+(IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, Z80_BYTE(I_word, 2));
        EMIT_PC_DISP (xlate0, 3);
                
        EMIT_INST_RRR(xlate1, ADD_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        EMIT_EOI     (xlate1);
      end
      
	ADD_A_n : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI_op, rA, rA, Z80_BYTE(I_word, 1));
        EMIT_F_MASK  (xlate0, 8'b11111111);
        EMIT_PC_DISP (xlate0, 2);	// NOV20
        EMIT_EOI     (xlate0);
      end
      
	ADD_A_r   : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rA, rA, REG_CONV8(I_word[26:24]));
        EMIT_F_MASK  (xlate0, 8'b11111111);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	ADD_HL_ss : //HL<-HL+ss//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, ADD16_op, rHL, rHL, REG_CONV_CELP(I_word[29:28]));
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b00111011);
        
        EMIT_EOI     (xlate0);
      end
      
	ADD_IX_pp : //IX<-IX+pp//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, ADD16_op, rIX, rIX, REG_CONV_CEXP(I_word[21:20]));
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b00111011);
        
        EMIT_EOI     (xlate0);
      end
      
	ADD_IY_rr : //IY<-IY+rr//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, ADD16_op, rIY, rIY, REG_CONV_CEYP(I_word[21:20]));
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b00111011);
        
        EMIT_EOI     (xlate0);
      end
      
	AND_s_1   : //A<-A AND r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, AND_op, rA, rA, REG_CONV8(I_word[26:24]));
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	AND_s_2   : //A<-A AND n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, ANDI_op, rA, rA, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	AND_s_3   : //A<-A AND (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRR(xlate1, AND_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	AND_s_4   : //A<-A AND (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, AND_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	AND_s_5   : //A<-A AND (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, AND_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	BIT_b_HL  : //Z<-~(HL)b//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);

        EMIT_INST_RRI(xlate1, GETBIT_op, rR0, rT0, {5'b00000,I_word[21:19]});
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_EOI     (xlate1);
      end
      
	BIT_b_IX_d: //Z<-~(IX+d)b//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);

        EMIT_INST_RRI(xlate1, GETBIT_op, rR0, rT0, {5'b00000,I_word[5:3]});
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_EOI     (xlate1);
      end
      
	BIT_b_IY_d: //Z<-~(IY+d)b//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);

        EMIT_INST_RRI(xlate1, GETBIT_op, rR0, rT0, {5'b00000,I_word[5:3]});
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_EOI     (xlate1);
      end
      
	BIT_b_r   : //Z<-~rb//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, GETBIT_op, rR0, REG_CONV8(I_word[18:16]), {5'b00000,I_word[21:19]});
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111110);
        
        EMIT_EOI     (xlate0);
      end
      
	CALL_cc_nn: ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(7);	// NOV20
        
        EMIT_INST_RRI(xlate0, (I_word[27] == 1'b1 ? GETBIT_op : NGETBIT_op), rT0, rF, Z80_CC_BPOS(I_word[29:27]));
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRI(xlate1, BEQ_op, rT0, rR0, 0);	// go next z80 instruction if false
        // condition is true 
        EMIT_INST_RRI(xlate2, MVPC_op, rT10, 0, 0);	
        
        // put PC onto the stack
        EMIT_INST_RRI(xlate3, ST_op, rT1, rSP, -1);
        EMIT_INST_RRI(xlate4, ST_op, rT0, rSP, -2);	// NOV20
        
        EMIT_INST_RRI(xlate5, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI (xlate6, J_op, 0, I_word[23:8]);
        EMIT_EOI     (xlate6);
      end
      
	CALL_nn   : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(5);	// NOV20
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);
        EMIT_PC_DISP (xlate0, 3);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);  // NOV20
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI (xlate4, J_op, 0, I_word[23:8]);
        EMIT_EOI     (xlate4);
      end
      
	CCF       : //CY<-~CY//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, NSETBIT_op, rF, rT0, 0);
        EMIT_F_MASK  (xlate1, 8'b00000010);	// NOV21
        EMIT_EOI     (xlate1);
      end
      
	CP_s_1    : //A - r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, SUB_op, rR0, rA, REG_CONV8(I_word[26:24]));
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	CP_s_2    : //A - n////////////////////////////////////////////////// NOV20
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SUBI_op, rR0, rA, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	CP_s_3    : //A - (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRR(xlate1, SUB_op, rR0, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	CP_s_4    : //A-(IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rR0, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	CP_s_5    : //A-(IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rR0, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	CPD       : //A-(HL), HL--, BC--/////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(6);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, -1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK  (xlate2, 8'b11111110);
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);	// read Z
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);
        EMIT_F_MASK  (xlate4, 8'b11111110);
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);  // set PV
        EMIT_EOI     (xlate5);
      end
      
	CPDR      : //CPD, if BC ==0 or A == (HL), terminate///////////////////////
      begin
        XLATE_VALID_SET(9);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, -1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK  (xlate2, 8'b11111110);
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);	// read Z
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);   // A - (HL)
        EMIT_F_MASK  (xlate4, 8'b11111110);
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);	// set PV. Until here, same as CPD
        
        EMIT_INST_RRI(xlate6, BEQ_op, rT0, rR0, 0);	// terminate if A-(HL) == 0
        
        EMIT_INST_RRI(xlate7, BEQ_op, rBC, rR0, 0);	// terminate if BC == 0
        
        EMIT_INST_RRI(xlate8, BEQ_op, rR0, rR0, -2);   // repeat always
        EMIT_EOI     (xlate8);
      end
	CPI       : //A-(HL), HL++, BC--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(6);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK  (xlate2, 8'b11111110);
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);
        EMIT_F_MASK  (xlate4, 8'b11111110);
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);               
        EMIT_EOI     (xlate5);
      end
      
	CPIR      : //CPI, if BC ==0 or A == (HL), terminate////////////////////////////
      begin
        XLATE_VALID_SET(9);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI16_op, rHL, rHL, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);
        EMIT_F_MASK  (xlate2, 8'b11111110);
        
        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);
        
        EMIT_INST_RRR(xlate4, SUB_op, rT0, rA, rT0);
        EMIT_F_MASK  (xlate4, 8'b11111110);
        
        EMIT_INST_RRI(xlate5, NSETBIT_op, rF, rT1, 2);
        
        EMIT_INST_RRI(xlate6, BEQ_op, rT0, rR0, 0);
        
        EMIT_INST_RRI(xlate7, BEQ_op, rBC, rR0, 0);
        
        EMIT_INST_RRI(xlate8, BEQ_op, rR0, rR0, -2);
        EMIT_EOI     (xlate8);
      end
      
	CPL       : //A <- ~A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, NOT_op, rA, rA, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b00111010);
        EMIT_EOI     (xlate0);
      end
      
	DAA       : //DAA//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, DAA_op, rA, rA, 0);	// F is taken care of by CORE
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111101);	// NOV20
        EMIT_EOI     (xlate0);
      end
      
	DEC_IX    : //IX--/////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIX, rIX, -1);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	DEC_IY    : //IY--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIY, rIY, -1);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	DEC_m_1   : //r--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, SUBI_op, REG_CONV8(I_word[29:27]), REG_CONV8(I_word[29:27]), 1);  // NOV20
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111110);
        
        EMIT_EOI     (xlate0);
      end
      
	DEC_m_2  : //(HL)--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRI(xlate1, SUBI_op, rT0, rT0, 1);  // NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	DEC_m_3   : // (IX+d)-- //////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRI(xlate1, SUBI_op, rT0, rT0, 1); // NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	DEC_m_4   : //(IY+d)--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRI(xlate1, SUBI_op, rT0, rT0, 1); // NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	DEC_ss    : //ss--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, REG_CONV_CELP(I_word[29:28]), REG_CONV_CELP(I_word[29:28]), -1);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	DI        : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, DI_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	DJNZ_e    : //Dec, and jump if not zero/////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, ADDI_op, rB, rB, -1);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, BNE_op, rB, rR0, I_word[23:16]);
        EMIT_EOI     (xlate1);
      end
      
	EI        : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, EI_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	EX_SP_HL  : //H <-> (SP+1), L <-> (SP)//////////////////////////
      begin
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ST_op, rL, rSP, 0);
        
        EMIT_INST_RRI(xlate3, ST_op, rH, rSP, 1);
        
        EMIT_INST_RRR(xlate4, ADD16_op, rHL, rT10, 0);	// NOV20
        
        EMIT_EOI     (xlate4);
      end
      
	EX_SP_IX  : //IXH <-> (SP+1), IXL <-> (SP)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(6);
        
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRR(xlate2, ADD16_op, rT32, rIX, 0);	// NOV20
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rSP, 0);	// NOV20
        
        EMIT_INST_RRI(xlate4, ST_op, rT3, rSP, 1);  // NOV20
        
        EMIT_INST_RRR(xlate5, ADD16_op, rIX, rT10, 0);  // NOV20 
        EMIT_EOI     (xlate5);
      end
      
	EX_SP_IY  : //IYH <-> (SP+1), IYL <-> (SP)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(6);
        
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRR(xlate2, ADD16_op, rT32, rIY, 0);  // NOV20
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rSP, 0);  // NOV20
        
        EMIT_INST_RRI(xlate4, ST_op, rT3, rSP, 1);  // NOV20
        
        EMIT_INST_RRR(xlate5, ADD16_op, rIY, rT10, 0);  // NOV20 NOV21
        EMIT_EOI     (xlate5);
      end
      
	EX_AF_AF  : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        
        EMIT_INST_RRI(xlate0, ADD16_op, rT10, rAF, 0); // NOV20
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ADD16_op, rAF, rAFs, 0);  // NOV20
        
        EMIT_INST_RRI(xlate2, ADD16_op, rAFs, rT10, 0);  // NOV20
        EMIT_EOI     (xlate2);
      end
      
	EX_DE_HL  : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        
        EMIT_INST_RRI(xlate0, ADD16_op, rT10, rDE, 0);	// NOV20
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ADD16_op, rDE, rHL, 0);  // NOV20
        
        EMIT_INST_RRI(xlate2, ADD16_op, rHL, rT10, 0);  // NOV20
        EMIT_EOI     (xlate2);
      end
      
	EXX       : //exchange BC, DE, HL //////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(9);
        
        EMIT_INST_RRI(xlate0, ADD16_op, rT10, rBC, 0); // NOV20
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ADD16_op, rBC, rBCs, 0); // NOV20
        
        EMIT_INST_RRI(xlate2, ADD16_op, rBCs, rT10, 0); // NOV20
        
        EMIT_INST_RRI(xlate3, ADD16_op, rT10, rDE, 0); // NOV20
        
        EMIT_INST_RRI(xlate4, ADD16_op, rDE, rDEs, 0); // NOV20
        
        EMIT_INST_RRI(xlate5, ADD16_op, rDEs, rT10, 0); // NOV20

        EMIT_INST_RRI(xlate6, ADD16_op, rT10, rHL, 0); // NOV20
        
        EMIT_INST_RRI(xlate7, ADD16_op, rHL, rHLs, 0); // NOV20
        
        EMIT_INST_RRI(xlate8, ADD16_op, rHLs, rT10, 0); // NOV20
        EMIT_EOI     (xlate8);
      end
      
	HALT      : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, BEQ_op, rR0, rR0, -1);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	IM0       : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	IM1       : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	IM2       : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	IN_A_n    : //A <- (n), noflags//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, IN_op, rA, rR0, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	IN_r_C    : //r <- (C) flag affected//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, IN_op, REG_CONV8(I_word[21:19]), rC, 0);
        EMIT_F_MASK  (xlate0, 8'b11111110);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	INC_HL    : //(HL)++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, 1);
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	INC_IX_d  : //(IX+d)++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, 1);
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	INC_IY_d  : //(IY+d)++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);

        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, 1);
        EMIT_F_MASK  (xlate1, 8'b11111110);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	INC_IX    : //IX++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIX, rIX, 1);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	INC_IY    : //IY++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, rIY, rIY, 1); // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	INC_r     : //r++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, ADDI_op, REG_CONV8(I_word[29:27]), REG_CONV8(I_word[29:27]), 1);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111110);
        
        EMIT_EOI     (xlate0);
      end
      
	INC_ss    : //CELP ++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI16_op, REG_CONV_CELP(I_word[29:28]), REG_CONV_CELP(I_word[29:28]), 1);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	IND       : //(HL) <- (C), HL--, B-- /////???check flags???/////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0);
        EMIT_PC_DISP (xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1);	// NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, SUBI16_op, rHL, rHL, 1);  // NOV20
        EMIT_EOI     (xlate3);
      end
      
	INDR      : //do IND, terminate if B becomes 0// ??? check flags ???////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0);	// NOV20
        EMIT_PC_DISP (xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1);  // NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, SUBI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI     (xlate4);
      end
      
	INI       : //(HL) <- (C), HL++, B-- ///??? check flags ???///////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0);
        EMIT_PC_DISP (xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1); // NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rHL, rHL, 1);
        EMIT_EOI     (xlate3);
      end
      
	INIR      : // INI, terminate b becomes 0// ??? check flags ???////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, IN_op, rT0, rC, 0); // NOV20
        EMIT_PC_DISP (xlate0, 2);

        EMIT_INST_RRI(xlate1, SUBI_op, rB, rB, 1); // NOV20
        EMIT_F_MASK  (xlate1, 8'b11111110);
                
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rHL, rHL, 1);
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI     (xlate4);
      end
      
	JP_HL     : //PC <- HL//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RI (xlate0, JR_op, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);        
        EMIT_EOI     (xlate0);
      end
      
	JP_IX     : //PC <- IX//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RI (xlate0, JR_op, rIX, 0);
        EMIT_PC_DISP (xlate0, 2);        
        EMIT_EOI     (xlate0);
      end
      
	JP_IY     : //PC <- IY //////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RI (xlate0, JR_op, rIY, 0);
        EMIT_PC_DISP (xlate0, 2);        
        EMIT_EOI     (xlate0);
      end
      
	JP_cc_nn  : //PC<-nn if cc is true//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, (I_word[27] == 1'b1 ? GETBIT_op : NGETBIT_op), rT0, rF, Z80_CC_BPOS(I_word[29:27]));
        EMIT_PC_DISP (xlate0, 3);
        
        EMIT_INST_RI (xlate1, JC_op, rT0, I_word[23:8]);
        EMIT_EOI     (xlate1);
      end
      
	JP_nn     : //PC<-nn//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RI (xlate0, J_op, 0, I_word[23:8]);
        EMIT_PC_DISP (xlate0, 3);
        EMIT_EOI     (xlate0);
      end
      
	JR_NC_e   : //branch if C==0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, BEQ_op, rT0, rR0, I_word[23:16]);
        EMIT_EOI     (xlate1);
      end
      
	JR_C_e    : //branch if C!=0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, BNE_op, rT0, rR0, I_word[23:16]);
        EMIT_EOI     (xlate1);
      end
      
	JR_e      : //branch always//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, BEQ_op, rR0, rR0, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	JR_NZ_e   : //branch if Z==0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 8'b00000110);	// Z, NOV20
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI (xlate1, BEQ_op, rT0, rR0, I_word[23:16]);
        EMIT_EOI     (xlate1);
      end
      
	JR_Z_e    : //branch if Z!=0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 8'b00000110); // Z, NOV20
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI (xlate1, BNE_op, rT0, rR0, I_word[23:16]);
        EMIT_EOI     (xlate1);
      end
      
	LD_BC_A   : //(BC)<-A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, rA, rBC, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_DE_A   : //(DE)<-A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, rA, rDE, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_HL_n   : //(HL)<-n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, ADDI_op, rT0, rR0, I_word[23:16]);	// NOV20
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate1);
      end
      
	LD_HL_r   : //(HL)<-r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, REG_CONV8(I_word[26:24]), rHL, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_IX_d_n : //(IX+d)<-n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, ADDI_op, rT0, rR0, I_word[7:0]);	// NOV20
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRI(xlate1, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate1);
      end
      
	LD_IX_d_r : //(IX+d)<-r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, REG_CONV8(I_word[18:16]), rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);
        EMIT_EOI     (xlate0);
      end
      
	LD_IY_d_n : //(IY+d)<-n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RRI(xlate0, ADDI_op, rT0, rR0, I_word[7:0]);	// NOV20
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRI(xlate1, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate1);
      end
      
	LD_IY_d_r : //(IY+d)<-r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ST_op, REG_CONV8(I_word[18:16]), rIY, I_word[15:8]); // NOV20
        EMIT_PC_DISP (xlate0, 3);
        EMIT_EOI     (xlate0);
      end
      
	LD_nn_A   : //(nn) <- A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[23:8]);
        EMIT_PC_DISP (xlate0, 3);
        
        EMIT_INST_RRI(xlate1, ST_op, rA, rT10, 0);
        EMIT_EOI     (xlate1);
      end
      
	LD_nn_dd  : //(nn+1)<-ddh, (nn)<-ddl //////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rR0, REG_CONV_CELP(I_word[21:20]));
        
        EMIT_INST_RRI(xlate2, ST_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rT10, 0);
        EMIT_EOI     (xlate3);
      end
      
	LD_nn_HL  : //(nn+1)<-H, (nn)<-L//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[23:8]);
        EMIT_PC_DISP (xlate0, 3);
                
        EMIT_INST_RRI(xlate1, ST_op, rH, rT10, 1);
        
        EMIT_INST_RRI(xlate2, ST_op, rL, rT10, 0);
        EMIT_EOI     (xlate2);
      end
      
	LD_nn_IX  : //(nn+1)<-IXh, (nn)<-IXl//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rR0, rIX);
                
        EMIT_INST_RRI(xlate2, ST_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rT10, 0);
        EMIT_EOI     (xlate3);
      end
      
	LD_nn_IY  : //(nn+1)<-IYh, (nn)<-IYl//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rR0, rIY); // NOV20
                
        EMIT_INST_RRI(xlate2, ST_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate3, ST_op, rT2, rT10, 0);
        EMIT_EOI     (xlate3);
      end
      
	LD_A_BC   : //A<-(BC)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, rA, rBC, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_A_DE   : //A<-(DE)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, rA, rDE, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_A_nn   : //A<-(nn)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[23:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRI(xlate1, LD_op, rA, rT10, 0);
        EMIT_EOI     (xlate1);
      end
      
	LD_A_I    : //A<-I//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);			// NOV20
        EMIT_INST_RRR(xlate0, ADD_op, rA, rR0, rI);
        EMIT_F_MASK  (xlate0, 8'b11111110); 
        // do something to get IFF2
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, MVIFF_op, rT0, rR0, 2);	// read iff2	NOV20
        
        EMIT_INST_RRI(xlate2, SETBIT_op, rF, rT0, 2);   // set PV with iff2  NOV20
        EMIT_EOI     (xlate2);			// NOV20
      end
      
	LD_A_R    : //A<-R//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);			// NOV20
        EMIT_INST_RRR(xlate0, ADD_op, rA, rR0, rR);
        EMIT_F_MASK  (xlate0, 8'b11111110); 
        // do something to get IFF2
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, MVIFF_op, rT0, rR0, 2);	// read iff2	NOV20
        
        EMIT_INST_RRI(xlate2, SETBIT_op, rF, rT0, 2);   // set PV with iff2  NOV20
        EMIT_EOI     (xlate2);			// NOV20
      end
      
	LD_dd_nn  : //ddh<-(nn+1), ddl<-(nn) CELP//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, LD_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rT2, rT10, 0);
        
        EMIT_INST_RRR(xlate3, ADD16_op, REG_CONV_CELP(I_word[21:20]), rT32, rR0);	// NOV20
        EMIT_EOI     (xlate3);
      end
      
	LD_dd_nn2  : //dd<-nn//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RI (xlate0, LIMM_op, REG_CONV_CELP(I_word[29:28]), I_word[23:8]);  // NOV20
        EMIT_PC_DISP (xlate0, 3);  // NOV20
        EMIT_EOI     (xlate0);
      end
      
	LD_HL_nn   : //H<-(nn+1), L<-(nn)////////////////check LD dd,(nn) (overlap)//////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[23:8]);	// NOV20
        EMIT_PC_DISP (xlate0, 3);
                
        EMIT_INST_RRI(xlate1, LD_op, rH, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rL, rT10, 0);
        EMIT_EOI     (xlate2);
      end
      
	LD_I_A     : //I<-A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rI, rA, rR0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	LD_IX_nn   : //IXh<-(nn+1), IXl<-(nn)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, LD_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rT2, rT10, 0);
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIX, rT32, rR0); // NOV20
        EMIT_EOI     (xlate3);
      end
      
	LD_IX_nn2  : //IX<-nn//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RI (xlate0, LIMM_op, rIX, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
        EMIT_EOI     (xlate0);
      end
      
	LD_IY_nn   : //IYh<-(nn+1), IYl<-(nn)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RI (xlate0, LIMM_op, rT10, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, LD_op, rT3, rT10, 1);
        
        EMIT_INST_RRI(xlate2, LD_op, rT2, rT10, 0);
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIY, rT32, rR0); // NOV20
        EMIT_EOI     (xlate3);
      end
      
	LD_IY_nn2  : //IY<-nn//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);		// NOV20
        EMIT_INST_RI (xlate0, LIMM_op, rIY, I_word[15:0]);
        EMIT_PC_DISP (xlate0, 4);
        EMIT_EOI     (xlate0);
      end
     
	LD_r_HL    : //r<-(HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, REG_CONV8(I_word[29:27]), rHL, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_r_IX_d  : //r<-(IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, REG_CONV8(I_word[21:19]), rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);
        EMIT_EOI     (xlate0);
      end
      
	LD_r_IY_d  : //r<-(IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, LD_op, REG_CONV8(I_word[21:19]), rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);
        EMIT_EOI     (xlate0);
      end
      
	LD_R_A     : //R<-A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR, rA, rR0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	LD_r_r     : //r<-r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, REG_CONV8(I_word[29:27]), REG_CONV8(I_word[26:24]), rR0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_r_n     : //r<-n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, ADDI_op, REG_CONV8(I_word[29:27]), rR0, I_word[23:16]); // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	LD_SP_HL   : //SP<-HL//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD16_op, rSP, rR0, rHL);  // NOV20
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	LD_SP_IX   : //SP<-IX//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD16_op, rSP, rR0, rIX);  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	LD_SP_IY   : //SP<-IY//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD16_op, rSP, rR0, rIY);	// NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	LDD        : //(DE)<-(HL), DE--, HL--, BC--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(9);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 8'b11000001);		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK  (xlate2, 8'b01000000);

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, -1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, -1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        EMIT_EOI     (xlate8);
      end
      
	LDDR       : //LDD, terminate if BC becomes 0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(10);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 8'b11000001);		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK  (xlate2, 8'b01000000);

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, -1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, -1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        
        EMIT_INST_RRI(xlate9, BNE_op, rBC, rR0, -2);
        EMIT_EOI     (xlate9);
      end
      
	LDI        : //(DE)<-(HL), DE++, HL++, BC--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(9);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 8'b11000001);		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK  (xlate2, 8'b01000000);

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, 1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        EMIT_EOI     (xlate8);
      end
      
	LDIR       : //LDI, terminate if BC == 0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(10);								// NOV20
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ANDI_op, rT2, rF, 8'b11000001);		// NOV20
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rBC, rBC, -1);  // NOV20
        EMIT_F_MASK  (xlate2, 8'b01000000);

        EMIT_INST_RRI(xlate3, GETBIT_op, rT1, rF, 6);

        EMIT_INST_RRI(xlate4, ADDI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate5, ST_op, rT0, rDE, 0);
        
        EMIT_INST_RRR(xlate6, ADD_op, rF, rT2, rR0);	  // NOV20
        
        EMIT_INST_RRI(xlate7, ADDI16_op, rDE, rDE, 1);
        
        EMIT_INST_RRI(xlate8, NSETBIT_op, rF, rT1, 2);
        
        EMIT_INST_RRI(xlate9, BNE_op, rBC, rR0, -2);
        EMIT_EOI     (xlate9);
      end
      
	NEG        : //A <- 0 - A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, SUB_op, rA, rR0, rA);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        EMIT_EOI     (xlate0);
      end
      
	OR_s_1   : //A<-A OR r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, OR_op, rA, rA, REG_CONV8(I_word[26:24]));
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	OR_s_2   : //A<-A OR n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, ORI_op, rA, rA, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	OR_s_3   : //A<-A OR (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRR(xlate1, OR_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	OR_s_4   : //A<-A OR (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, OR_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	OR_s_5   : //A<-A OR (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, OR_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	OTDR       : //(C)<-(HL), HL--, B--, repeat until B=0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK  (xlate1, 8'b01000010);

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, -1);	// NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI     (xlate4);
      end
      
	OTIR       : //(C)<-(HL), HL++, B--, repeat until B==0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(5);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK  (xlate1, 8'b01000010);

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, 1);  // NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        
        EMIT_INST_RRI(xlate4, BNE_op, rB, rR0, -2);
        EMIT_EOI     (xlate4);
      end
      
	OUT_C_r    : //(C)<-r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, OUT_op, REG_CONV8(I_word[21:19]), rC, 0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	OUT_n_A    : //(n) <- A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, OUT_op, rA, rR0, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	OUTD       : //(C)<-(HL), B--, HL--//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK  (xlate1, 8'b01000010);

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, -1);  // NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        EMIT_EOI     (xlate3);
      end
      
	OUTI       : //(C)<-(HL), B--, HL++//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ADDI_op, rB, rB, -1);
        EMIT_F_MASK  (xlate1, 8'b01000010);

        EMIT_INST_RRI(xlate2, ADDI16_op, rHL, rHL, 1); // NOV20
        
        EMIT_INST_RRI(xlate3, OUT_op, rT0, rC, 0);
        EMIT_EOI     (xlate3);
      end
      
	POP_IX     : //IXh<-(SP+1), IXl<-(SP), SP=SP+2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIX, rT10, rR0);  // NOV20
        EMIT_EOI     (xlate3);
      end
      
	POP_IY     : //IYh<-(SP+1), IYl<-(SP), SP=SP+2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RRR(xlate3, ADD16_op, rIY, rT10, rR0);  // NOV20
        EMIT_EOI     (xlate3);
      end
      
	POP_qq     : //qqh<=(SP+1), qql<=(SP), SP=SP+2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rSP, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RRR(xlate3, ADD16_op, REG_CONV_CELF(I_word[29:28]), rT10, rR0);  // NOV20
        EMIT_EOI     (xlate3);
      end
      
	PUSH_IX    : //(SP-2)<-IXl, (SP-1)<-IXh, SP--2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRR(xlate0, ADD16_op, rT10, rIX, rR0); // NOV20
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);  // NOV20
        EMIT_EOI     (xlate3);
      end
      
	PUSH_IY    : //(SP-2)<-IYl, (SP-1)<-IYh, SP--2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRR(xlate0, ADD16_op, rT10, rIY, rR0);  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);  // NOV20
        EMIT_EOI     (xlate3);
      end
      
	PUSH_qq    : //(SP-2)<-qql, (SP-1)<-qqh, SP--2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRR(xlate0, ADD16_op, rT10, REG_CONV_CELF(I_word[29:28]), rR0); // NOV20
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);  //NOV20
        EMIT_EOI     (xlate3);
      end
      
	RES_b_m_1  : //rb<-0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SETBIT_op, REG_CONV8(I_word[18:16]), rR0, {5'b00000,I_word[21:19]});
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	RES_b_m_2  : //(HL)b<-0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rT0, rR0, {5'b00000,I_word[21:19]});
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	RES_b_m_3  : //(IX+d)b<-0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rT0, rR0, {5'b00000,I_word[5:3]});
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RES_b_m_4  : //(IY+d)b<-0//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rT0, rR0, {5'b00000,I_word[5:3]});
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RET        : //PCl<-(SP), PCh<-(SP+1), SP++2//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT1, rSP, 1);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2);  // NOV20
        
        EMIT_INST_RI (xlate3, JR_op, rT10, 0);
        EMIT_EOI     (xlate3);
      end
      
	RET_cc     : //if cc is true, do RET//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(6);

        EMIT_INST_RRI(xlate0, (I_word[27] == 1'b1 ? GETBIT_op : NGETBIT_op), rT0, rF, Z80_CC_BPOS(I_word[29:27]));
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, BEQ_op, rT0, rR0, 0);  // if false, goto next inst

        EMIT_INST_RRI(xlate2, LD_op, rT1, rSP, 1);
        
        EMIT_INST_RRI(xlate3, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate4, ADDI16_op, rSP, rSP, 2); // NOV20
        
        EMIT_INST_RI (xlate5, JR_op, rT10, 0);
        EMIT_EOI     (xlate5);
      end
      
	RETI       : //treat this same as RET/////////////should be investigated/////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT1, rSP, 1);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2); // NOV20
                
        EMIT_INST_RI (xlate3, JR_op, rT10, 0);
        EMIT_EOI     (xlate3);
      end
      
	RETN       : //treat this same as RET//////////////////reti + how to deal with iff?? ////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, LD_op, rT1, rSP, 1);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, LD_op, rT0, rSP, 0);
        
        EMIT_INST_RRI(xlate2, ADDI16_op, rSP, rSP, 2); // NOV20
        
        EMIT_INST_RI (xlate3, JR_op, rT10, 0);
        EMIT_EOI     (xlate3);
      end
      
	RL_m_1     : //RL r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H04);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_EOI     (xlate0);
      end
      
	RL_m_2     : //RL (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H04);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	RL_m_3     : //RL (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H04);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RL_m_4     : //RL (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]); // NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H04);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RLA        : //RLA A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 8'H05);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b00111011);  // NOV20
        
        EMIT_EOI     (xlate0);
      end
      
	RLC_HL     : //RLC (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H00);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
       
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	RLC_IX_d   : //RLC (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H00);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RLC_IY_d   : ////////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H00);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RLC_r      : //RLC r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H00);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	RLCA       : //RLCA A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 8'H01);
        EMIT_F_MASK  (xlate0, 8'b00111011);  // NOV20
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	RLD        : //three way rotation////////////////////////////////////////////NOV20
      begin
        XLATE_VALID_SET(8);
        EMIT_INST_RRI(xlate0, LD_op, rT2, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, GET4_op, rT1, rT2, 1);
        
        EMIT_INST_RRI(xlate2, GET4_op, rT0, rT2, 0);
        
        EMIT_INST_RRI(xlate3, GET4_op, rT3, rA, 1);
        
        EMIT_INST_RRI(xlate4, GET4_op, rT2, rA, 0);
        
        EMIT_INST_RRR(xlate5, MERGE44_op, rA, rT3, rT1);
        EMIT_F_MASK  (xlate5, 8'b11111110);
        
        EMIT_INST_RRR(xlate6, MERGE44_op, rT2, rT0, rT2);
        
        EMIT_INST_RRI(xlate7, ST_op, rT2, rHL, 0);
        EMIT_EOI     (xlate7);
      end
      
	RR_m_1     : //RR r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H06);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_EOI     (xlate0);
      end
      
	RR_m_2     : //RR (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H06);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	RR_m_3     : //RR (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H06);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RR_m_4     : //RR (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H06);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RRA        : //RRA A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 8'H07);
        EMIT_F_MASK  (xlate0, 8'b00111011);  // NOV20
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	RRC_m_1     : //RRC r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H02);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	RRC_m_2     : //RRC (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H02);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	RRC_m_3     : //RRC (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H02);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RRC_m_4     : //RRC (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]); // NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H02);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	RRCA       : //RRCA A//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, rA, rA, 8'H03);
        EMIT_F_MASK  (xlate0, 8'b00111011);  // NOV20
        EMIT_PC_DISP (xlate0, 1);
        EMIT_EOI     (xlate0);
      end
      
	RRD        : //three way rotation//////////////////////////////////////////////// NOV20
      begin
        XLATE_VALID_SET(8);
        EMIT_INST_RRI(xlate0, LD_op, rT2, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRI(xlate1, GET4_op, rT1, rT2, 1);
        
        EMIT_INST_RRI(xlate2, GET4_op, rT0, rT2, 0);
        
        EMIT_INST_RRI(xlate3, GET4_op, rT3, rA, 1);
        
        EMIT_INST_RRI(xlate4, GET4_op, rT2, rA, 0);
        
        EMIT_INST_RRR(xlate5, MERGE44_op, rA, rT3, rT0);
        EMIT_F_MASK  (xlate5, 8'b11111110);
        
        EMIT_INST_RRR(xlate6, MERGE44_op, rT2, rT2, rT1);
        
        EMIT_INST_RRI(xlate7, ST_op, rT2, rHL, 0);
        EMIT_EOI     (xlate7);
      end
      
	RST_p      : //(SP-1)<-PCH, (SP-2)<-PCL, PC<-????//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);		// PC has been incremented already
        EMIT_PC_DISP (xlate0, 1);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);		// NOV20
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI (xlate4, J_op, 0, {2'b0,I_word[29:27],3'b000,8'b0});	// swapped IMM address
        EMIT_EOI     (xlate4);
      end
      
	SBC_A_s_1: //A<-A-r-CY//////////////////////////////////////////////////
      begin
        // cannot set transitive flags correctly
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 1);
        EMIT_INST_RRR(xlate1, ADD_op, rT0, rT0, REG_CONV8(I_word[26:24]));  // NOV20
        EMIT_INST_RRR(xlate2, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate2, 8'b11111111);
        EMIT_EOI     (xlate2);
      end
      
	SBC_A_s_2: //A<-A-n-CY///////////////////////////////////////////////
      begin
        // flag problems
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_INST_RRI(xlate1, ADDI_op, rT0, rT0, I_word[23:16]); // NOV20     
        EMIT_INST_RRR(xlate2, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate2, 8'b11111111);
        EMIT_EOI     (xlate2);
      end
      
	SBC_A_s_3: //A<-A-(HL)-CY//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rHL, 0);
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  // NOV20
            
        EMIT_INST_RRR(xlate3, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate3, 8'b11111111);
        EMIT_EOI     (xlate3);
      end
      
	SBC_A_s_4: //A<-A-(IX+d)-CY//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIX, I_word[15:8]);  // NOV20
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  // NOV20
            
        EMIT_INST_RRR(xlate3, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate3, 8'b11111111);
        EMIT_EOI     (xlate3);
      end
      
	SBC_A_s_5: //A<-A-(IY+d)-CY//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(4);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 3);
        
        EMIT_INST_RRI(xlate1, LD_op, rT1, rIY, I_word[15:8]);  // NOV20
        
        EMIT_INST_RRR(xlate2, ADD_op, rT0, rT0, rT1);  // NOV20
            
        EMIT_INST_RRR(xlate3, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate3, 8'b11111111);
        EMIT_EOI     (xlate3);
      end
      
	SBC_HL_ss  : //HL<-HL-ss-CY//////////////////////////////////////////////////
      begin
        // flag problems
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, GETBIT_op, rT0, rF, 0);
        EMIT_PC_DISP (xlate0, 2);
        
        EMIT_INST_RRR(xlate1, ADD16_op, rT32, rT0, REG_CONV_CELP(I_word[21:20]));  // NOV20
              
        EMIT_INST_RRR(xlate2, SUB16_op, rHL, rHL, rT32);
        EMIT_F_MASK  (xlate2, 8'b11111111);
        EMIT_EOI     (xlate2);
      end
      
	SCF        : //CY<-1//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, NSETBIT_op, rF, rR0, 0);
        EMIT_PC_DISP (xlate0, 1);
        
        EMIT_INST_RRI(xlate1, SETBIT_op, rF, rR0, 1);	// NOV20
        
        EMIT_INST_RRI(xlate2, SETBIT_op, rF, rR0, 4);	// NOV23
        EMIT_EOI     (xlate2);
      end
      
	SET_b_HL  : //(HL)b<-1//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);

        EMIT_INST_RRI(xlate1, NSETBIT_op, rT0, rR0, {5'b00000,I_word[21:19]}); // NOV23

        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);  // NOV23
        EMIT_EOI     (xlate2);
      end
      
	SET_b_IX_d: //(IX+d)b<-1//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);

        EMIT_INST_RRI(xlate1, NSETBIT_op, rT0, rR0, {5'b00000,I_word[5:3]}); // NOV23
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]); // NOV23
        EMIT_EOI     (xlate2);
      end
      
	SET_b_IY_d: //(IY+d)b<-1//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);

        EMIT_INST_RRI(xlate1, NSETBIT_op, rT0, rR0, {5'b00000,I_word[5:3]}); // NOV23

        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]); // NOV23
        EMIT_EOI     (xlate2);
      end
      
	SET_b_r   : //rb<-1//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, NSETBIT_op, REG_CONV8(I_word[18:16]), rR0, {5'b00000,I_word[21:19]});
        EMIT_PC_DISP (xlate0, 2);        
        EMIT_EOI     (xlate0);
      end
      
	SLA_m_1     : //SLA r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H08);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_EOI     (xlate0);
      end
      
	SLA_m_2     : //SLA (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H08);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	SLA_m_3     : //SLA (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H08);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SLA_m_4     : //SLA (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]); // NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H08);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SRA_m_1     : //SRA r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H09);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_EOI     (xlate0);
      end
      
	SRA_m_2     : //SRA (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H09);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	SRA_m_3     : //SRA (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H09);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SRA_m_4     : //SRA (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]); //NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H09);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SRL_m_1     : //SRL r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H0A);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	SRL_m_2     : //SRL (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H0A);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	SRL_m_3     : //SRL (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H0A);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SRL_m_4     : //SRL (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]); // NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H0A);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SUB_s_1   : //A<-A-r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, SUB_op, rA, rA, REG_CONV8(I_word[26:24]));
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	SUB_s_2   : //A<-A - n//////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, SUBI_op, rA, rA, I_word[23:16]); // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	SUB_s_3   : //A<-A-(HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRR(xlate1, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	SUB_s_4   : //A<-A-(IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	SUB_s_5   : //A<-A-(IY+d)////////////////////////////////////////////////// // NOV20
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, SUB_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	XOR_s_1   : //A<-A xor r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRR(xlate0, XOR_op, rA, rA, REG_CONV8(I_word[26:24]));
        EMIT_PC_DISP (xlate0, 1);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	XOR_s_2   : //A<-A xor n//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        
        EMIT_INST_RRI(xlate0, XORI_op, rA, rA, I_word[23:16]);
        EMIT_PC_DISP (xlate0, 2);
        EMIT_F_MASK  (xlate0, 8'b11111111);
        
        EMIT_EOI     (xlate0);
      end
      
	XOR_s_3   : //A<-A xor (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 1);

        EMIT_INST_RRR(xlate1, XOR_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	XOR_s_4   : //A<-A xor (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, XOR_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end
      
	XOR_s_5   : //A<-A xor (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(2);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 3);

        EMIT_INST_RRR(xlate1, XOR_op, rA, rA, rT0);
        EMIT_F_MASK  (xlate1, 8'b11111111);
        
        EMIT_EOI     (xlate1);
      end

//////////////////////////////////
// UNDOCUMENTED
//////////////////////////////////

	SLL_m_1     : //SLL r//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRI(xlate0, SHIFTROTATE_op, REG_CONV8(I_word[18:16]), REG_CONV8(I_word[18:16]), 8'H0B);
        EMIT_F_MASK  (xlate0, 8'b11111111);  // NOV20
        EMIT_PC_DISP (xlate0, 2);
        EMIT_EOI     (xlate0);
      end
      
	SLL_m_2     : //SLL (HL)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rHL, 0);
        EMIT_PC_DISP (xlate0, 2);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H0B);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rHL, 0);
        EMIT_EOI     (xlate2);
      end
      
	SLL_m_3     : //SLL (IX+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIX, I_word[15:8]);
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H0B);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIX, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end
      
	SLL_m_4     : //SLL (IY+d)//////////////////////////////////////////////////
      begin
        XLATE_VALID_SET(3);
        EMIT_INST_RRI(xlate0, LD_op, rT0, rIY, I_word[15:8]); // NOV20
        EMIT_PC_DISP (xlate0, 4);
                
        EMIT_INST_RRI(xlate1, SHIFTROTATE_op, rT0, rT0, 8'H0B);
        EMIT_F_MASK  (xlate1, 8'b11111111);  // NOV20
        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rIY, I_word[15:8]);
        EMIT_EOI     (xlate2);
      end

//////////////////////////////////
// interrupt handler
//parameter INT_handler = 254, NMI_handler = 255;
//////////////////////////////////

	INT_handler     : //(SP-1)<-PCh, (SP-2)<-PCl, SP--2, J 0x0038///////////NOV20
      begin
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);  
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI (xlate4, J_op, 0, 16'H3800);
        EMIT_EOI     (xlate4);
      end

	NMI_handler     : //(SP-1)<-PCh, (SP-2)<-PCl, SP--2, J 0x0066///////////NOV20
      begin
        XLATE_VALID_SET(5);
        
        EMIT_INST_RRI(xlate0, MVPC_op, rT10, 0, 0);
                
        EMIT_INST_RRI(xlate1, ST_op, rT1, rSP, -1);        
        EMIT_INST_RRI(xlate2, ST_op, rT0, rSP, -2);  
        
        EMIT_INST_RRI(xlate3, ADDI16_op, rSP, rSP, -2);
        
        EMIT_INST_RI (xlate4, J_op, 0, 16'H6600);
        EMIT_EOI     (xlate4);
      end
      
    default: ///////////////////////////////////////////////
      begin
        XLATE_VALID_SET(1);
        EMIT_INST_RRR(xlate0, ADD_op, rR0, rR0, rR0);
        EMIT_PC_DISP (xlate0, 4);		// it is likely that the offset is 4
        EMIT_EOI     (xlate0);
      end
  endcase
end
endmodule

///////////////////////////////////////////////////////////
// test module just for fun
///////////////////////////////////////////////////////////
//module testmodule (CLK, RST, flush, I_wait, I_byte, Q_full, NMI, INT,
//               uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3, z80dec_stall);
//input CLK, RST, flush, I_wait, Q_full, NMI, INT;
//input [7:0] I_byte;
//output [38:0] uop0, uop1, uop2, uop3;
//output WR_EN0, WR_EN1, WR_EN2, WR_EN3, z80dec_stall;
//
//wire [31:0] I_word;
//wire I_word_rdy, xlator_stall;
//wire [7:0] z80_I_ID;
//wire invalid_inst;
//
//xlator XLATOR (CLK, RST, flush, NMI, INT, I_word, I_word_rdy, z80_I_ID, Q_full,
//               uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3,
//               xlator_stall);
//z80_decoder DECODER (CLK, RST, flush, I_wait, I_byte, xlator_stall, z80dec_stall, I_word, I_word_rdy, z80_I_ID, invalid_inst) ;
//
//endmodule


//module testmodule2 (CLK, RST, flush, NMI, INT, I_wait, I_byte, pipe_stall, uop, invalid_inst, z80dec_stall);
//
//input CLK, RST, flush, I_wait, NMI, INT, pipe_stall;
//input [7:0] I_byte;
//output [38:0] uop;
//output z80dec_stall, invalid_inst;

//wire [38:0] uop0, uop1, uop2, uop3;
//wire WR_EN0, WR_EN1, WR_EN2, WR_EN3;

//wire [31:0] I_word;
//wire I_word_rdy;
//wire [7:0] z80_I_ID;
//wire Q_full;
//wire xlator_stall;

//z80_decoder DECODER (CLK, RST, (flush | NMI | INT), I_wait, I_byte, xlator_stall, z80dec_stall, I_word, I_word_rdy, z80_I_ID, invalid_inst) ;

//xlator XLATOR (CLK, RST, flush, NMI, INT, I_word, I_word_rdy, z80_I_ID, Q_full,
//               uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3,
//               xlator_stall);

//uop_queue UOP_Q (CLK, RST, (flush | NMI | INT), uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3, pipe_stall, uop, Q_full) ;
//endmodule




