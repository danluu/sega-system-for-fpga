module Processor(CLK, RESET_B, WAIT_B, WR_B, RD_B, MREQ_B, IORQ_B, NMI_B, INT_B,
                 DATA_OUT, DATA_IN, ADDR,
                 // fetch side signals
                 WAIT_F_B, FLUSH_B, FHRQ_B, DATA_FETCH, ADDR_FETCH
// debug
, DEBUG_UOP_OUT, DEBUG_SEQNPC_OUT, DEBUG_RF_DUMP, DEBUG_PIPE_STALL, DEBUG_TAKEN
, DEBUG_ADDR_OUT, DEBUG_RDATA_OUT, DEBUG_WDATA_OUT
, DEBUG_UOP_XLATOR_OUT, DEBUG_MEM_SEQ_NPC
);

// general interface
input CLK, RESET_B, WAIT_B;
output WR_B, RD_B, MREQ_B, IORQ_B;
input NMI_B, INT_B;
output [7:0] DATA_OUT;
input  [7:0] DATA_IN;
output [15:0] ADDR;

// fetch mem interface
input WAIT_F_B;
output FLUSH_B, FHRQ_B;
input [7:0] DATA_FETCH;
output [15:0] ADDR_FETCH;

// debug
output [38:0] DEBUG_UOP_OUT;
output [15:0] DEBUG_SEQNPC_OUT;
output [223:0] DEBUG_RF_DUMP;
output DEBUG_PIPE_STALL, DEBUG_TAKEN;
output [15:0] DEBUG_ADDR_OUT;
output [7:0] DEBUG_RDATA_OUT, DEBUG_WDATA_OUT;
output [38:0] DEBUG_UOP_XLATOR_OUT;
output [15:0] DEBUG_MEM_SEQ_NPC;

// wires
wire [38:0] Iword;    // trans - core
wire pipe_stall;       // trans - core
wire [15:0] targetPC; // trans - core
wire intern_INT, intern_NMI; // trans - core
wire flush;          // trans - core
assign FLUSH_B = ~flush; // core - fetchmem

wire IORQ, MREQ, RD, WR; // core - mem(outside)
assign IORQ_B = ~IORQ;
assign MREQ_B = ~MREQ;
assign RD_B   = ~RD;
assign WR_B   = ~WR;

wire I_MREQ;  // translator - fetchmem
assign FHRQ_B = ~I_MREQ;

// debug
assign DEBUG_UOP_XLATOR_OUT = Iword;

risc_core       CORE
                (CLK, ~RESET_B, ~INT_B, ~NMI_B, Iword,                      // inputs
                 pipe_stall, targetPC, intern_INT, intern_NMI, flush,       // outputs
                 ADDR, DATA_IN, DATA_OUT, IORQ, MREQ, RD, WR, ~WAIT_B        // to/from memory, active high
// debug
, DEBUG_UOP_OUT, DEBUG_SEQNPC_OUT, DEBUG_RF_DUMP, DEBUG_PIPE_STALL, DEBUG_TAKEN
, DEBUG_ADDR_OUT, DEBUG_RDATA_OUT, DEBUG_WDATA_OUT, DEBUG_MEM_SEQ_NPC
);    


translator_part TRANSLATOR
                (CLK, ~RESET_B, I_MREQ, ~WAIT_F_B, ADDR_FETCH, DATA_FETCH,  // external interface
                 flush, targetPC, intern_NMI, intern_INT, pipe_stall,       // inputs from RISC core
                 Iword);                                                    // outputs to RISC core                 

endmodule
