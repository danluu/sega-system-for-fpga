module bitops (A, B, C, opp, OUT, flags) ;

//this module executes the opperatons of getbit(0), ngetbit(1), setbit(2)
//nsetbit(3), get4(4), merge44(5) based on the opp code shown in ()

//input [15:0] A ;  //either Ra or Rb from the reg file
//input [15:0] B ;  //either Rb or Imm 
//input [15:0] C ;  //only used for set bit and nsetbit.  this is the register Ra

input [15:0] A;	//reg Ra
input [15:0] B; //reg Rb
input [15:0] C; //imm
//input [1:0] iff;//flip flop values for iff1, iff2

input [2:0] opp ; //code specifying the opperation
output [15:0] OUT ;  //result form instruction
output [7:0] flags;

wire [15:0] A;
wire [15:0] B;
wire [2:0] opp;
//wire [1:0] iff;

reg [15:0] OUT;
reg [7:0] flags;

//temp value 
reg [7:0] temp;
reg zero;
reg parity;


always@(A or B or C or opp or zero or parity or temp)
begin

	temp = 8'b0;
	OUT = 16'b0;
	zero=1'b0;
	parity=1'b0;
//selects mode of opperation

	case(opp)
		3'b000:	
			begin  //getbit
			//8 bit opp  MSB is set to zero
			//B is the register to get bit from (Rb)
			//C is an 8 bit immediate that selects the bit (unsigned int)
			//OUT is a 1 if the bit is 1 and 0 otherwise
			
			OUT = {15'b0, A[C[3:0]]};
			zero = ~|({15'b0, A[C[3:0]]});
			//flags = s, z, x, h, x, pv, n, c
			flags = {1'b0,zero, OUT[5], 1'b1, OUT[3], 1'b0, 1'b0, 1'b1}; 
			end
		
		3'b001:  
			begin  //ngetbit
			//same as get bit but complemented
			OUT = {15'b0, ~A[C[3:0]]};
			zero = ~|({15'b0, ~A[C[3:0]]});
			//flags = s, z, x, h, x, pv, n, c
			flags = {1'b0,zero, OUT[5], 1'b1, OUT[3], 1'b0, 1'b0, 1'b1}; 
			end
		
		3'b010:	
			begin  //setbit
			//sets the bit in reg a defined by the imm. to the value of b
			//B is the register to get the bit from (Rb) 
			//C is the immediate to specify which bit
			//OUT is the new value of A 
					
			temp = A[7:0];
			temp[C[2:0]] = |(B);
			
			OUT = {A[15:8], temp[7:0]};
			//flags not defined for this opperation
			flags = 8'b0;
			end		
		
		3'b011:	
			begin  //nsetbit
			//same as set bit except bit is complemented
			
			temp = A[7:0];
	 		temp[C[2:0]] = ~|(B);
			

			OUT = {A[15:8], temp[7:0]};
			//flags not defined for this opperation
			flags = 8'b0;
			end
		
		3'b100:
			begin  //get4
			//returns high nibble of Rb if imm is not zero
			//returns low nibble of Rb if imm is zero
			//B is regsiter to get from (Rb)
			//C is imm-- to determine which bits to get			
			
			//flags not defined for this opperation
			flags = 8'b0;
			if(C == 16'b0)
				OUT[15:0] = {12'b0, A[3:0]};
			else 
				OUT[15:0] = {12'b0, A[7:4]};
			end
		
		3'b101:
			begin  //merge44
			//combines two nibbles into a byte
			//this uses the low order nibbles from each register 		
			//A is first register (Ra)  Rb in instr spec
			//B is second register (Rb) Rc in instr spec
			//OUT is the combined byte
			
		 	OUT = {8'b0, A[3:0], B[3:0]};			
			parity = ~^({8'b0, A[3:0], B[3:0]});
			zero = ~|({8'b0, A[3:0], B[3:0]});
			//flags = s,      z,    x,      h,    x,      pv,      n,    c
			flags = {OUT[7],zero, OUT[5], 1'b0, OUT[3], parity, 1'b0, 1'b1}; 
			end

			default:  
			begin
			OUT = 16'b0;
			zero=1'b0;
			parity=1'b0;
			flags = 8'b0;
			end	
	endcase
end//always
endmodule 


