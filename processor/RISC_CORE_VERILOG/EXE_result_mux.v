module EXE_result_mux(opcode, ALU_result, IFF1, IFF2, Imm, seqNPC, Result);

input [5:0] opcode;
input [15:0] ALU_result;
input IFF1, IFF2;
input [1:0] Imm;
input [15:0] seqNPC;
output	[15:0] Result;

reg [15:0] Result;

always@(opcode or ALU_result or IFF1 or IFF2 or Imm or seqNPC)
begin

case(opcode)

	6'h10:		//mvPC instruction
			begin
				Result = seqNPC;
			end

6'h1C:		//mviff instruction
			begin
				if (Imm == 2'h1) Result = {15'b0, IFF1};
				else if (Imm == 2'h2) Result = {15'b0, IFF2};
				else Result = 16'b0; 
			end

default:		//all ALU instructions
			begin
			Result = ALU_result;
			end
endcase

end//always

endmodule
