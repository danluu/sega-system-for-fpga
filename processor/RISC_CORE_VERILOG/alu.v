module alu(opcode,Src0,Src1,IMM,Result,Flags);

input[5:0] opcode;
input [15:0] Src0,Src1,IMM;
output [15:0] Result;
output [7:0] Flags;

wire [5:0] opcode;
wire [15:0] Src0,Src1,IMM;//inputs
wire [15:0] daa_out;//one of the inputs to adder
wire [1:0] cadd_alu;//control for mux3
wire [15:0] add_in;//input to adder
wire [15:0] add_out,bits_out,logic_out,rotate_out;//ouput of each module
wire	[1:0] calu_out_alu;
wire [7:0] add_flag,bits_flag,logic_flag,daa_flag,rotate_flag;
wire [2:0] cflag_out_alu;
wire daa_carry_out,daa_n_out;
wire op_add_alu;
wire [1:0]op_logic_alu;
wire [2:0]op_bitops_alu;
wire add_size_alu;

mux3 m3(
	.MA(Src1),
	.MB(IMM),
	.MC(daa_out),
	.S(cadd_alu),
	.O(add_in));

//Result
mux4 m4(
	.MA(add_out),
	.MB(bits_out),
	.MC(logic_out),
	.MD(rotate_out),
	.S(calu_out_alu),
	.O(Result));

//Flags 
mux5 m5(
	.MA(add_flag),
	.MB(bits_flag),
	.MC(logic_flag),
	.MD(rotate_flag),
	.ME(daa_flag),
	.S(cflag_out_alu),
	.O(Flags));





 
adder a1(Src0,add_in,op_add_alu, add_size_alu  ,add_out,add_flag);

bitops b1(Src0, Src1, IMM, op_bitops_alu , bits_out, bits_flag);

logic_block l1(Src0, add_in,op_logic_alu , logic_out, logic_flag);

rotate_shift r1(Src0[7:0], IMM[7:0], Src1[7:0], rotate_out,rotate_flag);

daa d1(Src0[7:0],Src1[7:0], daa_out ,daa_carry_out, daa_n_out);

alu_control c1(opcode, cadd_alu, cflag_out_alu,calu_out_alu,op_add_alu,op_logic_alu,op_bitops_alu,add_size_alu); 

daa_flags_out df1(add_out,add_flag,daa_n_out,daa_carry_out,daa_flag);



endmodule