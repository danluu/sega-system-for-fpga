module logic_block (A, B, opp, OUT, flags) ;

//this module does the bitwise opperations on 2 16 bit inputs.  The opperations are
//and, or, xor, not.  based on the opp signal 00, 01, 10, 11 respectively

input [15:0] A ;
input [15:0] B ;
input [1:0] opp ;
//input [7:0] fin ;
output [15:0] OUT ;
output [7:0] flags;

wire [15:0] A;
wire [15:0] B;
wire [1:0] opp;
//wire [7:0] fin;
reg [15:0] OUT;
reg [7:0] flags;

reg zero;
reg parity;

	//selects mode of opperation and(0), or(1), xor(2), not(3)
always@(A or B or opp )
begin
	zero = 1'b0;
	parity = 1'b0;
	//flags = fin;
	case(opp)
		2'b00:	begin		//and
					OUT = A & B;
					zero = ~|(A & B);
					parity = ~^(A & B);
   					//flags = {S,      Z,    X,    H,    X,       P/V,    N,    C}
					flags = {OUT[7], zero, OUT[5], 1'b1, OUT[3], parity, 1'b0, 1'b0};
					end
		2'b01: begin  //or
					OUT = A | B;
					zero = ~|(A | B);
					parity = ~^(A|B);
					flags = {OUT[7], zero, OUT[5], 1'b0, OUT[3], parity, 1'b0, 1'b0};
					end
		2'b10:	begin  //xor
					OUT = A ^ B;
					zero = ~|(A ^ B);
					parity = ~^(A^B);  //= 0 if even parity
					flags = {OUT[7], zero, OUT[5], 1'b0, OUT[3], parity, 1'b0, 1'b0};
					end
		2'b11:	begin  //not
					OUT = ~A;
					flags = 8'b00010010;
					//flags[4] = 1'b1;
					//flags[1] = 1'b1;
					end
		default: begin
					  OUT = 16'b0;
						flags = 8'b0;
						end
				
	endcase
end//always
endmodule 


