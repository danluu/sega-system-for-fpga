module exe_stage(Wr_id_in,Fmask_in,opcode,IMM,Rd_data0,Rd0_id,
							Rd_data1,Rd1_id,PC_EXE_stage,EOI_EXE_stage,mem_pipe_stall,
							WB_Result,
							WB_Wr_id,WB_Flags,WB_Fmask,paging_RQ,
							bubble,EOI_RF_stage,CLK,RST,extern_INT, extern_NMI,
							Wr_id_out,MEMctrl,Flags,Result,Src1, seqNPC,Fmask_out,
							EOI_out,flush0,flush1,targetPC,PCupdate,intern_INT, intern_NMI);				
			

input [4:0] Wr_id_in;
input [7:0] Fmask_in;
input [5:0] opcode;
input [15:0] IMM;
input [15:0] Rd_data0;
input [4:0] Rd0_id;
input [15:0] Rd_data1;
input [4:0] Rd1_id;
input [15:0] PC_EXE_stage;//seqNPC
input EOI_EXE_stage;
input mem_pipe_stall;
input [15:0] WB_Result;
input [4:0] WB_Wr_id;
input [7:0] WB_Flags;
input [7:0] WB_Fmask;
input paging_RQ;

input bubble;
input EOI_RF_stage;
input CLK;
input RST;
input extern_INT ;
input extern_NMI;

output [4:0] Wr_id_out;
output [7:0] Fmask_out;
output [6:0] MEMctrl;
output [7:0] Flags;
output [15:0] Result;
output [15:0] Src1;
output [15:0] seqNPC;
output EOI_out;
output flush0;
output flush1;

output [15:0] targetPC;
output PCupdate;
output intern_INT;
output intern_NMI;

wire flush2;
wire [15:0] Src0;
wire [15:0] br_targetPC;
wire br_taken;
wire [15:0] ALU_Result;
wire interrupt_RQ;
wire [6:0]MEMctrl_in;
wire [7:0]Flags_in;
wire [15:0]Result_in;
wire [15:0]Src1_in;
wire IFF1,IFF2;

ALU_input_sel ais1(Src0, Src1_in,
       Rd_data0, Rd0_id, Rd_data1, Rd1_id,
       Result, Wr_id_out, Flags, Fmask_out,
       WB_Result, WB_Wr_id, WB_Flags, WB_Fmask);



alu a1(opcode,Src0,Src1_in,IMM,ALU_Result,Flags_in);

EXE_result_mux exr1(opcode, ALU_Result, IFF1, IFF2, IMM[1:0], PC_EXE_stage, Result_in);

branch_unit b1(Src0, Src1_in, IMM, opcode, PC_EXE_stage, br_targetPC, br_taken);


flush_unit fu1(flush0, flush1, flush2, targetPC, PCupdate,
                   br_targetPC, br_taken, paging_RQ, interrupt_RQ, mem_pipe_stall,
                   bubble, EOI_RF_stage, EOI_EXE_stage, EOI_out,
                   PC_EXE_stage, seqNPC);



interrupt_handler ih1(CLK, RST, extern_INT, extern_NMI, intern_INT, intern_NMI, interrupt_RQ, flush0,
                         IFF1, IFF2, opcode, mem_pipe_stall);


memstage_ctrl mc1(MEMctrl_in, opcode, flush1);


EXE_stage_latch esl1(CLK,RST,
                       Wr_id_in,Fmask_in,MEMctrl_in,
                       Flags_in,Result_in,Src1_in,
                       PC_EXE_stage,EOI_EXE_stage, flush2,mem_pipe_stall,
                       Wr_id_out,Fmask_out,MEMctrl,
                       Flags,Result,Src1,
                       EOI_out,seqNPC);






endmodule
