module adder(A, B, opp, size, OUT, flags) ;




input [15:0] A;	//input A can be one or 2 bytes
input [15:0] B;	//input B can be one or 2 bytes
input opp;				  //0 if addition, 1 if subtraction
input size; 				//tells if the opperation is going to be 
						  //1 or 2 bytes  (size = 0 for 8bits)

wire [15:0] A;
wire [15:0] B;
wire opp;
wire size;

output [15:0] OUT;  //solution to the addition or subtraction
output [7:0] flags; //z80 flags SZXHXPNC


reg [7:0] flags;
//reg [15:0] OUT;

wire cout_a, cout_b, cout_c, cout_d;



//create adders for use in the design

//instanciate 4 bit adder
add_4 add_nibA (
	.A(A[3:0]),
	.B(B[3:0]),
	.C_OUT(cout_a),
	.ADD(~opp),
	.S(OUT[3:0]));

//instansiate 4 bit adder with carry in
add_4c add_nibB (
	.A(A[7:4]),
	.B(B[7:4]),
	.C_IN(cout_a),
	.C_OUT(cout_b),
	.ADD(~opp),
	.S(OUT[7:4]));

//instansiate 4 bit adder with carry in
add_4c add_nibC (
	.A(A[11:8]),
	.B(B[11:8]),
	.C_IN(cout_b),
	.C_OUT(cout_c),
	.ADD(~opp),
	.S(OUT[11:8]));

//instansiate 4 bit adder with carry in
add_4c add_nibD (
	.A(A[15:12]),
	.B(B[15:12]),
	.C_IN(cout_c),
	.C_OUT(cout_d),
	.ADD(~opp),
	.S(OUT[15:12]));


//instanciate 8 bit adder
//add_8 add_byte (
//	.A(A[15:8]),
//	.B(B[15:8]),
//	.C_IN(cout_b),
//	.C_OUT(cout_c),
//	.ADD(~opp),
//	.S(OUT[15:8]));


always@(A or B or opp or size or OUT or cout_a or cout_b or cout_c or cout_d)
begin


//set flag register
//S Z X H X P/V N C



//these dont depend on the case.  3, 5 are output 3, 5
flags[1] = opp;
flags[3] = OUT[3];
flags[5] = OUT[5];

case(size)

1'b0:	
	begin //flags for 8bit opperation
	flags[0] = (opp) ? ~cout_b : cout_b;	 //C
	if (~opp) flags[2] = (~A[7] & ~B[7] & OUT[7]) | (A[7] & B[7] & ~OUT[7]);  //P/V
	else	flags[2] = (~A[7] & B[7] & OUT[7]) | (A[7] & ~B[7] & ~OUT[7]);  //P/V
	flags[4] = (opp) ? ~cout_a : cout_a;		//H
	flags[6] = ~|(OUT[7:0]);	//Z
	flags[7] = OUT[7];			//S
	end
1'b1:
	begin //flags for 16bit opperation
	flags[0] = (opp) ? ~cout_d : cout_d;
	if(~opp) flags[2] = (~A[15] & ~B[15] & OUT[15]) | (A[15] & B[15] & ~OUT[15]);  //P/V	
	else	flags[2] = (~A[15] & B[15] & OUT[15]) | (A[15] & ~B[15] & ~OUT[15]);  //P/V
	flags[4] = (opp) ? ~cout_c : cout_c;
	flags[6] = ~|(OUT[15:0]) ;
	flags[7] = OUT[15];
	end

default:	flags = 8'b0;

endcase

end//always
endmodule
