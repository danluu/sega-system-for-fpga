module branch_unit(Src0, Src1, Imm, Opcode, seqNPC, targetPC, taken);

input [15:0] Src0, Src1, Imm;
input [5:0] Opcode;
input [15:0] seqNPC;

output [15:0] targetPC;
output taken;

reg [15:0] targetPC;
reg taken;
 
//this module computes the new branch address, and wheather its taken

always@(Src0 or Src1 or Imm or Opcode or seqNPC)
begin

case(Opcode)

	6'h20:	//j on Imm, always taken
		begin
		taken = 1'b1;
		targetPC = Imm;
		end

	6'h21:	//j on reg, always taken
		begin
		taken = 1'b1;
		targetPC = Src0;
		end

	6'h22:	//j on Imm, conditional
		begin
		targetPC = Imm;
		if (~|(Src0)) taken = 1'b0;
		else taken = 1'b1;
		end

	6'h23:	//j on reg, conditional
		begin
		targetPC = Src1;
		if (~|(Src0)) taken = 1'b0;
		else taken = 1'b1;
		end

	6'h24:	//bne
		begin
		targetPC = seqNPC + Imm;
		if (Src0 == Src1) taken = 1'b0;
		else taken = 1'b1;
		end

	6'h25:	//beq
		begin
		targetPC = seqNPC + Imm;
		if (Src0 == Src1) taken = 1'b1;
		else taken = 1'b0;
		end

	default:		begin taken = 1'b0; targetPC = seqNPC; end

endcase

end//always

endmodule
