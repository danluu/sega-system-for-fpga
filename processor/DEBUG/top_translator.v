module translator_part (CLK, RST, I_MREQ, I_wait, I_addr, I_data,     // external interface
                        flush, targetPC, intern_NMI, intern_INT, pipe_stall,   // inputs from RISC core
                        OUT_uop);                                              // outputs to RISC core

input CLK, RST, flush, intern_NMI, intern_INT, pipe_stall, I_wait;
input [15:0] targetPC;
input [7:0] I_data;
output [15:0] I_addr;
output [38:0] OUT_uop;
output I_MREQ;

wire z80dec_stall;
wire [38:0] uop0, uop1, uop2, uop3;
wire WR_EN0, WR_EN1, WR_EN2, WR_EN3;
wire [31:0] I_word;
wire I_word_rdy;
wire [7:0] z80_I_ID;
wire Q_full;
wire xlator_stall;
wire invalid_inst;


z80fetcher FETCHER (CLK, RST, flush, I_wait, z80dec_stall, targetPC, I_MREQ, I_addr) ;

// NOV26 ikim: changed I_wait to I_wait | !I_mreq
z80_decoder DECODER (CLK, RST, flush, (I_wait | (~I_MREQ)), I_data, xlator_stall, z80dec_stall, I_word, I_word_rdy, z80_I_ID, invalid_inst) ;

xlator XLATOR (CLK, RST, flush, intern_NMI, intern_INT, I_word, I_word_rdy, z80_I_ID, Q_full,
               uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3,
               xlator_stall);

uop_queue UOP_Q (CLK, RST, flush, uop0, uop1, uop2, uop3, WR_EN0, WR_EN1, WR_EN2, WR_EN3, pipe_stall, OUT_uop, Q_full) ;


/* debug */
//wire [8*34-1:0] outstring0, outstring1, outstring2, outstring3, outstring_q;
//DEBUG_uop_decoder xlatorout0(outstring0, uop0);
//DEBUG_uop_decoder xlatorout1(outstring1, uop1);
//DEBUG_uop_decoder xlatorout2(outstring2, uop2);
//DEBUG_uop_decoder xlatorout3(outstring3, uop3);

//DEBUG_uop_decoder uopqout(outstring_q, OUT_uop);
endmodule 

