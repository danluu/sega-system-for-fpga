module risc_core(CLK, RST, extern_INT, extern_NMI, Iword,                                   // inputs
                 pipe_stall, targetPC, intern_INT, intern_NMI, flush0,                      // outputs
                 D_addr, D_data_in, D_data_out, IORQ, MREQ, RD, WR, D_wait);                // to/from memory, active high

							
input CLK, RST, extern_INT, extern_NMI;
input [38:0] Iword; // from translator

output pipe_stall;  // to translator
output [15:0] targetPC; // to translator
output intern_INT, intern_NMI, flush0; // to translator

// memory inout
output [15:0] D_addr;
input  [7:0] D_data_in;
output [7:0] D_data_out;
output IORQ, MREQ, RD, WR;
input  D_wait;

//RF stage outputs
wire [5:0] opcode_fdup;
wire [15:0] IMM;
wire [4:0] Wr_id_in;
wire [7:0] Fmask_in;
wire EOI_EXE_stage;
wire [15:0]Rd_data0;
wire [4:0] Rd0_id;
wire [15:0] Rd_data1;
wire [4:0] Rd1_id;
wire [15:0] PC_EXE_stage;
wire bubble;
wire EOI_RF_stage;

//EXE stage outputs
wire [4:0] Wr_id_out;
wire [7:0]Fmask_out;
wire [6:0]MEMctrl;
wire [7:0] Flags;
wire [15:0]Result;
wire [15:0]Src1;
wire [15:0]seqNPC;
wire EOI_out;
wire flush0;
wire flush1;
wire flush2;
wire [15:0]targetPC_out;
wire PCupdate;

//Mem stage outputs
wire [4:0] Wr_id;
wire [7:0] Fmask;
wire [15:0] Result_out;
wire [7:0] Flags_out;
wire mem_pipe_stall;
wire paging_RQ;

RF_Stage rf1(Iword, mem_pipe_stall, flush1, PCupdate, targetPC_out, 
					 Wr_id, Fmask, Result_out, Flags_out,
						 CLK, RST, 
						//outputs
						opcode_fdup, IMM, Wr_id_in, Fmask_in, EOI_EXE_stage, Rd_data0, 
						Rd0_id, Rd_data1, Rd1_id,PC_EXE_stage , pipe_stall, 
						targetPC, bubble, EOI_RF_stage);

exe_stage ex1(Wr_id_in,Fmask_in,opcode_fdup,IMM,Rd_data0,Rd0_id,
							Rd_data1,Rd1_id,PC_EXE_stage,EOI_EXE_stage,mem_pipe_stall,
							Result_out,Wr_id,Flags_out,Fmask,paging_RQ,
							bubble,EOI_RF_stage,CLK,RST,extern_INT, extern_NMI,
							//outputs
							Wr_id_out,MEMctrl,Flags,Result,Src1, seqNPC,Fmask_out,
							EOI_out,flush0,flush1,targetPC_out,PCupdate,intern_INT, intern_NMI);		

MEM_stage me1(Wr_id_out, Fmask_out, MEMctrl, Src1, Result, seqNPC, EOI_out, Flags, flush0, CLK, RST, // from EXE stage / other stages
                 D_addr, D_data_in, D_data_out, IORQ, MREQ, RD, WR, D_wait,                 // to/from memory, active high
		 Wr_id, Fmask, Result_out, Flags_out,    // WB stage output, to RF stage
                 mem_pipe_stall, paging_RQ);             // control output to other stages
                 

endmodule
