///////////////////////////////////////////////
//  DEBUG_CPUtracer
//  dump out the current register contents,
//  seq_nPC, to a file
//////////////////////////////////////////////

module DEBUG_CPUtracer(CLK, RESET, RF_dump, seq_NPC, pipe_stall, uop, taken
, addr, rdata, wdata  // for memtrace
);

input CLK, RESET;
//AF, BC, DE, HL, SP, IX, IY, AF', BC', DE', HL', IR, T10, T32
input [223:0] RF_dump;
input [15:0]  seq_NPC;
input         pipe_stall;
input [38:0]  uop;
input         taken; // taken branch / jump (set in ALU stage)
input [15:0]  addr;
input [7:0]   rdata, wdata;

integer FILE_uoptrace;
integer FILE_z80trace;
integer FILE_memtrace;
integer FILE_uoptrace_string;

reg [31:0] z80_inst_counter; /* # z80 instructions */
wire [8*34-1:0] outstring;

`include "uISA.def.v"

DEBUG_uop_decoder UOP_DECODER(outstring, uop);

always@(posedge CLK)
begin
  if(RESET == 1'b1)
    begin
      z80_inst_counter = 0;
      // open file, start tracing 
      //FILE_uoptrace_string = $fopen("H:/FINAL_PROCESSOR/DEBUG/uoptrace_string.txt");
      //FILE_uoptrace = $fopen("H:/FINAL_PROCESSOR/DEBUG/uoptrace.txt");
      //FILE_z80trace = $fopen("H:/FINAL_PROCESSOR/DEBUG/z80trace.txt");
      //FILE_memtrace = $fopen("H:/FINAL_PROCESSOR/DEBUG/memtrace.txt");

      FILE_uoptrace_string = $fopen("E:/554/uoptrace_string.txt");
      FILE_uoptrace = $fopen("E:/554/uoptrace.txt");
      FILE_z80trace = $fopen("E:/554/z80trace.txt");
      FILE_memtrace = $fopen("E:/554/memtrace.txt");
    end
  else
    begin
  
      // determine if we have to dump status
      if(pipe_stall == 0)
        begin
            
          // increase the instruction counter
          if(uop[38:36] != 3'b000)
          z80_inst_counter = z80_inst_counter + 1;
                    
          // uop trace
          if(!((uop[26:0] == 0) && (uop[38:36] == 0))) // if it isn't nop
            begin
              $fwrite(FILE_uoptrace_string, "%.8x, PC %.4x: %s  ", z80_inst_counter, seq_NPC, outstring);
              $display("%.8x, PC %.4x: %s  ", z80_inst_counter, seq_NPC, outstring);
              $fwrite(FILE_uoptrace_string, "        reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
                      RF_dump[223:208] & 16'HFFD7, RF_dump[207:192], RF_dump[191:176]
                      , RF_dump[175:160], RF_dump[159:144], RF_dump[143:128], RF_dump[127:112]
                      , RF_dump[111:96], RF_dump[95:80], RF_dump[79:64], RF_dump[63:48]
                      , /* RF_dump[47:32], */ RF_dump[31:16], RF_dump[15:0]);
              $display("        reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
                      RF_dump[223:208] & 16'HFFD7, RF_dump[207:192], RF_dump[191:176]
                      , RF_dump[175:160], RF_dump[159:144], RF_dump[143:128], RF_dump[127:112]
                      , RF_dump[111:96], RF_dump[95:80], RF_dump[79:64], RF_dump[63:48]
                      , /* RF_dump[47:32], */ RF_dump[31:16], RF_dump[15:0]);

              // for comparison
              $fwrite(FILE_uoptrace, "%.8x, PC %.4x:", z80_inst_counter, seq_NPC);
              $fwrite(FILE_uoptrace, "      reg: %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
                      RF_dump[223:208] & 16'HFFD7, RF_dump[207:192], RF_dump[191:176]
                      , RF_dump[175:160], RF_dump[159:144], RF_dump[143:128], RF_dump[127:112]
                      , RF_dump[111:96], RF_dump[95:80], RF_dump[79:64], RF_dump[63:48]
                      , /* RF_dump[47:32], */ RF_dump[31:16], RF_dump[15:0]);

            end              

  
          // z80 trace
          if((uop[27] == 1'b1) || (taken == 1'b1)) // taken branch or EOI, dump status
            if(!((uop[26:0] == 0) && (uop[38:36] == 0)))
            begin
              $fwrite(FILE_z80trace, "%.8x, PC:%.4x, %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
                      z80_inst_counter, seq_NPC, RF_dump[223:208] & 16'HFFD7, RF_dump[207:192], RF_dump[191:176]
                      , RF_dump[175:160], RF_dump[159:144], RF_dump[143:128], RF_dump[127:112]
                      , RF_dump[111:96], RF_dump[95:80], RF_dump[79:64], RF_dump[63:48]
                      , /* RF_dump[47:32], */ RF_dump[31:16], RF_dump[15:0]);
              $display("%.8x, PC:%.4x, %.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x,%.4x\n",
                      z80_inst_counter, seq_NPC, RF_dump[223:208] & 16'HFFD7, RF_dump[207:192], RF_dump[191:176]
                      , RF_dump[175:160], RF_dump[159:144], RF_dump[143:128], RF_dump[127:112]
                      , RF_dump[111:96], RF_dump[95:80], RF_dump[79:64], RF_dump[63:48]
                      , /* RF_dump[47:32], */ RF_dump[31:16], RF_dump[15:0]);
            end
            
          // memtrace
          if((uop[26:21] == IN_op) || (uop[26:21] == OUT_op) || (uop[26:21] == LD_op) || (uop[26:21] == ST_op))
          begin
              // $fwrite(FILE_memtrace, "%.8x, PC %.4x: %s  ", z80_inst_counter, seq_NPC, outstring);
              $fwrite(FILE_memtrace, "%.8x, PC %.4x:  ", z80_inst_counter, seq_NPC);
              $fwrite(FILE_memtrace, "addr: %.4x, data %.2x\n", ((uop[26:21] == IN_op) || (uop[26:21] == OUT_op)) ? {8'b0, addr[7:0]}:addr, ((uop[26:21] == IN_op) || (uop[26:21] == LD_op)) ? rdata : wdata);          

              $display("%.8x, PC %.4x: %s  ", z80_inst_counter, seq_NPC, outstring);
              $display("addr: %.4x, data %.2x\n", ((uop[26:21] == IN_op) || (uop[26:21] == OUT_op)) ? {8'b0, addr[7:0]}:addr, ((uop[26:21] == IN_op) || (uop[26:21] == LD_op)) ? rdata : wdata);          
          end
        end 
    end
end
endmodule
              
              


///////////////////////////////////////////////
//  DEBUG_uop_decoder
//  this module decode a uop into a disassembled
//  form in Modelsim
//  Hook this module simply into any wires w/ uops
//  In the Modelsim waveform output, you have to
//  change the radix of the signal to ASCII
//
//  OUTPUT format:
//  RRR: @ +? (SZXHXPNC) opcode Rt, Rs, Rd
//  RRI: @ +? (SZXHXPNC) opcode Rt, Rs, 0xIMM8
//  RI : @ +? (SZXHXPNC) opcode Rt, 0xIMM16
//  where 
//    @  : EOI     (invisible if EOI is 0)
//    +? : PC_disp (invisible if it is 0)
//    (SZXHXPNC) : Fmask ('-' if a bit is 0)
//////////////////////////////////////////////

module DEBUG_uop_decoder(String, uop);
input [38:0] uop;

wire [2:0] PC_disp;
wire [7:0] Fmask;
wire EOI;
wire [5:0] opcode;
wire [4:0] Rd, Rs, Rt;
wire [15:0] IMM16;
wire [7:0]  IMM8;

parameter num_char_string = 34;
output [8*num_char_string-1:0] String;
reg [8*num_char_string-1:0] String;

assign PC_disp = uop[38:36];
assign Fmask = uop[35:28];
assign EOI = uop[27];
assign opcode = uop[26:21];
assign Rd = uop[20:16];
assign Rs = uop[15:11];
assign Rt = uop[10:6];
assign IMM16 = uop[15:0];
assign IMM8 = uop[7:0];

`include "uISA.def.v"
parameter num_char_opcode = 7;
reg [8 * num_char_opcode - 1 :0] op_name;
reg [1:0] inst_format;

/////////////////////////////////////////////////////////////////////OPCODE decoder
parameter RRR = 2'b00, RRI = 2'b01, RI = 2'b10;
task I_DECODE;
output [1:0] IFORMAT;
output [8 * num_char_opcode - 1 :0] OPNAME;
input [5:0] OPCODE;
begin
  case(OPCODE)
    /////////////////////////////////////////// RRR format
    ADD_op:
      begin
        IFORMAT = RRR;
        OPNAME = "ADD    ";
      end
    SUB_op:
      begin
        IFORMAT = RRR;
        OPNAME = "SUB    ";
      end	  
    ADD16_op:
      begin
        IFORMAT = RRR;
        OPNAME = "ADD16  ";
      end	  
    SUB16_op:
      begin
        IFORMAT = RRR;
        OPNAME = "SUB16  ";
      end	  
    AND_op:
      begin
        IFORMAT = RRR;
        OPNAME = "AND    ";
      end	  
    OR_op:
      begin
        IFORMAT = RRR;
        OPNAME = "OR     ";
      end	  
    XOR_op:
      begin
        IFORMAT = RRR;
        OPNAME = "XOR    ";
      end	  
    MERGE44_op:
      begin
        IFORMAT = RRR;
        OPNAME = "MERGE44";
      end	  
    EI_op:
      begin
        IFORMAT = RRR;
        OPNAME = "EI     ";
      end	  
    DI_op:
      begin
        IFORMAT = RRR;
        OPNAME = "DI     ";
      end	  

    //////////////////////////////////////////RRI format  
    ADDI_op:
      begin
        IFORMAT = RRI;
        OPNAME = "ADDI   ";
      end	  
    ADDI16_op:
      begin
        IFORMAT = RRI;
        OPNAME = "ADDI16 ";
      end	  
    SUBI_op:
      begin
        IFORMAT = RRI;
        OPNAME = "SUBI   ";
      end	  
    SUBI16_op:
      begin
        IFORMAT = RRI;
        OPNAME = "SUBI16 ";
      end	  
    ANDI_op:
      begin
        IFORMAT = RRI;
        OPNAME = "ANDI   ";
      end	  
    ORI_op:
      begin
        IFORMAT = RRI;
        OPNAME = "ORI    ";
      end	  
    XORI_op:
      begin
        IFORMAT = RRI;
        OPNAME = "XORI   ";
      end	  
    NOT_op:
      begin
        IFORMAT = RRI;
        OPNAME = "NOT    ";
      end	  
    SHIFTROTATE_op:
      begin
        IFORMAT = RRI;
        OPNAME = "SHFTRT ";
      end	  
    GET4_op:
      begin
        IFORMAT = RRI;
        OPNAME = "GET4   ";
      end	  
    MVPC_op:
      begin
        IFORMAT = RRI;
        OPNAME = "MVPC   ";
      end	  
    MVIFF_op:
      begin
        IFORMAT = RRI;
        OPNAME = "MVIFF  ";
      end	  
    DAA_op:
      begin
        IFORMAT = RRI;
        OPNAME = "DAA    ";
      end	  
    GETBIT_op:
      begin
        IFORMAT = RRI;
        OPNAME = "GETBIT ";
      end	  
    NGETBIT_op:
      begin
        IFORMAT = RRI;
        OPNAME = "NGETBIT";
      end	  
    SETBIT_op:
      begin
        IFORMAT = RRI;
        OPNAME = "SETBIT ";
      end	  
    NSETBIT_op:
      begin
        IFORMAT = RRI;
        OPNAME = "NSETBIT";
      end	  
    JRC_op:
      begin
        IFORMAT = RRI;
        OPNAME = "JRC    ";
      end	  
    BNE_op:
      begin
        IFORMAT = RRI;
        OPNAME = "BNE    ";
      end	  
    BEQ_op:
      begin
        IFORMAT = RRI;
        OPNAME = "BEQ    ";
      end	  
    LD_op:
      begin
        IFORMAT = RRI;
        OPNAME = "LD     ";
      end	  
    ST_op:
      begin
        IFORMAT = RRI;
        OPNAME = "ST     ";
      end	  
    IFF2IFF1_op:
      begin
        IFORMAT = RRI;
        OPNAME = "IFF21  ";
      end	  
    
    IN_op:
      begin
        IFORMAT = RRI;
        OPNAME = "IN     ";
      end
      	        
    OUT_op:
      begin
        IFORMAT = RRI;
        OPNAME = "OUT    ";
      end	        
      
    ///////////////////////////////////////RI format
    J_op:
      begin
        IFORMAT = RI;
        OPNAME = "J      ";
      end	  
    JR_op:
      begin
        IFORMAT = RI;
        OPNAME = "JR     ";
      end	  
    JC_op:
      begin
        IFORMAT = RI;
        OPNAME = "JC     ";
      end	  
    LIMM_op:
      begin
        IFORMAT = RI;
        OPNAME = "LIMM   ";
      end	  
    IM_op:
      begin
        IFORMAT = RI;
        OPNAME = "IM     ";
      end	  
    
	default:
      begin
        IFORMAT = RRI;
        OPNAME = "*INVAL*";
	  end
	  
  endcase
end
endtask


parameter num_char_reg = 3;
////////////////////////// Register decoder
function [8 * num_char_reg - 1 :0] REGNAME;
input [4:0] REG_ID;
begin
  case(REG_ID)
    rR0:
      REGNAME = " R0";
    rA:
      REGNAME = "  A";
    rF:
      REGNAME = "  F";
    rB:
      REGNAME = "  B";
    rC:
      REGNAME = "  C";
    rD:
      REGNAME = "  D";
    rE:
      REGNAME = "  E";
    rH:
      REGNAME = "  H";
    rL:
      REGNAME = "  L";
    rI:
      REGNAME = "  I";
    rR:
      REGNAME = "  R";
    rT0:
      REGNAME = " T0";
    rT1:
      REGNAME = " T1";
    rT2:
      REGNAME = " T2";
    rT3:
      REGNAME = " T3";

    rSP:
      REGNAME = " SP";
    rAF:
      REGNAME = " AF";
    rBC:
      REGNAME = " BC";
    rDE:
      REGNAME = " DE";
    rHL:
      REGNAME = " HL";
    rIX:
      REGNAME = " IX";
    rIY:
      REGNAME = " IY";
    rT10:
      REGNAME = "T10";
    rT32:
      REGNAME = "T32";
    rAFs:
      REGNAME = "AF'";
    rBCs:
      REGNAME = "BC'";
    rDEs:
      REGNAME = "DE'";
    rHLs:
      REGNAME = "HL'";
 
    default:
      REGNAME = "XXX";
  endcase
end
endfunction

////////////////////////// simple HEX decoder
function [8 * 1 - 1 :0] HEXNAME;
input [3:0] HEX_NUMBER;
begin
  case(HEX_NUMBER)
    4'H0:
      HEXNAME = "0";
    4'H1:
      HEXNAME = "1";
    4'H2:
      HEXNAME = "2";
    4'H3:
      HEXNAME = "3";
    4'H4:
      HEXNAME = "4";
    4'H5:
      HEXNAME = "5";
    4'H6:
      HEXNAME = "6";
    4'H7:
      HEXNAME = "7";
    4'H8:
      HEXNAME = "8";
    4'H9:
      HEXNAME = "9";
    4'HA:
      HEXNAME = "A";
    4'HB:
      HEXNAME = "B";
    4'HC:
      HEXNAME = "C";
    4'HD:
      HEXNAME = "D";
    4'HE:
      HEXNAME = "E";
    4'HF:
      HEXNAME = "F";
  endcase
end
endfunction    

parameter num_char_IMM8 = 4;
///////////////////////////// IMM8 decoder
function [8 * num_char_IMM8 -1 :0] IMM8NAME;
input[7:0] IMM8_NUMBER;
begin
  IMM8NAME = {"0x", HEXNAME(IMM8_NUMBER[7:4]), HEXNAME(IMM8_NUMBER[3:0])};
end
endfunction

parameter num_char_IMM16 = 6;
///////////////////////////// IMM16 decoder
function [8 * num_char_IMM16 -1 :0] IMM16NAME;
input[15:0] IMM16_NUMBER;
begin
  IMM16NAME = {"0x", HEXNAME(IMM16_NUMBER[15:12]), HEXNAME(IMM16_NUMBER[11:8]),
                HEXNAME(IMM16_NUMBER[7:4]), HEXNAME(IMM16_NUMBER[3:0])};
end
endfunction
  
parameter num_char_FLAG = 8;
///////////////////////////// FLAG decoder
function [8 * num_char_FLAG -1 :0] FLAGNAME;
input[7:0] FLAGS;
begin
  FLAGNAME = "--------";
  if(FLAGS[7] == 1'b1)
    FLAGNAME[7 * 8 + 7 : 7 * 8] = "S";
  if(FLAGS[6] == 1'b1)
    FLAGNAME[6 * 8 + 7 : 6 * 8] = "Z";
  if(FLAGS[5] == 1'b1)
    FLAGNAME[5 * 8 + 7 : 5 * 8] = "X";
  if(FLAGS[4] == 1'b1)
    FLAGNAME[4 * 8 + 7 : 4 * 8] = "H";
  if(FLAGS[3] == 1'b1)
    FLAGNAME[3 * 8 + 7 : 3 * 8] = "X";
  if(FLAGS[2] == 1'b1)
    FLAGNAME[2 * 8 + 7 : 2 * 8] = "P";
  if(FLAGS[1] == 1'b1)
    FLAGNAME[1 * 8 + 7 : 1 * 8] = "N";
  if(FLAGS[0] == 1'b1)
    FLAGNAME[0 * 8 + 7 : 0 * 8] = "C";
end
endfunction 
  	  
parameter num_char_PCdisp = 2;
///////////////////////////// PC displacement decoder
function [8 * num_char_PCdisp -1 :0] PCDISPNAME;
input[2:0] PC_DISP;
begin
  case(PC_DISP)
    3'b000:
      PCDISPNAME = "  ";
    3'b001:
      PCDISPNAME = "+1";
    3'b010:
      PCDISPNAME = "+2";
    3'b011:
      PCDISPNAME = "+3";
    3'b100:
      PCDISPNAME = "+4";
    default
      PCDISPNAME = "XX";
  endcase
end
endfunction

parameter num_char_EOI = 1;
///////////////////////////// EOI decoder
function [8 * num_char_EOI -1 :0] EOINAME;
input EOIBIT;
begin
  if(EOIBIT == 1'b1) EOINAME = "@";
  else EOINAME = " ";
end
endfunction


/////////////////////////////////////////////main decoder
always@(uop or PC_disp or Fmask or EOI or opcode or Rd or Rs or Rt or IMM16 or IMM8)
begin
  if(uop[26:0] == 27'b0)
    begin
      inst_format = RRR;
      op_name  = "NOP    ";
    end
  else
    I_DECODE(inst_format, op_name, opcode);
  
  String[(num_char_string - 1) * 8 + 7:(num_char_string - 1) * 8] = EOINAME(EOI);
  String[(num_char_string - 2) * 8 + 7:(num_char_string - 3) * 8] = PCDISPNAME(PC_disp);
  String[(num_char_string - 4) * 8 + 7:(num_char_string - 4) * 8] = "(";
  String[(num_char_string - 5) * 8 + 7:(num_char_string - 12) * 8] = FLAGNAME(Fmask);
  String[(num_char_string - 13) * 8 + 7:(num_char_string - 14) * 8] = ") ";
  String[(num_char_string - 15) * 8 + 7:(num_char_string - 21) * 8] = op_name;
  String[(num_char_string - 22) * 8 + 7:(num_char_string - 22) * 8] = " ";
    
  case(inst_format)
    RRR:
      String[(num_char_string - 23) * 8 + 7: (num_char_string - 34) * 8]
       = {REGNAME(Rd), ",", REGNAME(Rs), ",", REGNAME(Rt), " "};
    RRI:
      String[(num_char_string - 23) * 8 + 7: (num_char_string - 34) * 8]
       = {REGNAME(Rd), ",", REGNAME(Rs), ",", IMM8NAME(IMM8)};
    RI:
      String[(num_char_string - 23) * 8 + 7: (num_char_string - 34) * 8]
       = {REGNAME(Rd), ",", IMM16NAME(IMM16), "  "};
    default:
      String[(num_char_string - 23) * 8 + 7: (num_char_string - 34) * 8]
       = "decoder bug ";
  endcase
end

endmodule



