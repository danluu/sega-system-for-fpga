module fields_decoder (Iword, Rd0_id, Rd1_id, Imm, Wr_id) ;

input [38:0] Iword ;
output [4:0] Rd0_id ;
output [4:0] Rd1_id ;
output [15:0] Imm ;
output [4:0] Wr_id ;


reg [4:0] Rd0_id;
reg [4:0] Rd1_id;
reg [15:0] Imm;
reg [4:0] Wr_id;
reg [2:0]	type;

//this is the fields decoder module as specified by the module definitions file

//inputs:
//Iword:	a 39 bit instrction word.  comming from the translator
//
//outputs:
//Rd0_id:		the specifier for the first read register
//Rd1_id:		the specifier for the second read register
//Imm:		an immidiate value
//Wr_id:		the specifier for the wrote register


//any output not used by the current instruction will be set to zero

//these output are specified by which catergory of instruction we are dealing with
//catergories are RRR, RRI, RI, and special



always@(Iword)
begin
	
	//type = 00 for RRR, 01 for RRI, 10 for RI, 11 for DAA/shift
	
	//Iword[26:21] = opcode
	case(Iword[26:21])		//assign the type
		6'h00:begin type = 3'b000; end //type RRR
		6'h02:begin type = 3'b000; end
		6'h03:begin type = 3'b000; end
		6'h05:begin type = 3'b000; end
		6'h06:begin type = 3'b000; end
		6'h08:begin type = 3'b000; end
		6'h0A:begin type = 3'b000; end
		6'h0F:begin type = 3'b000; end
		6'h17:begin type = 3'b000; end
		6'h18:begin type = 3'b000; end
	
		6'h01:begin type = 3'b001; end		//type RRI
		6'h04:begin type = 3'b001; end
		6'h1A:begin type = 3'b001; end
		6'h1B:begin type = 3'b001; end
		6'h07:begin type = 3'b001; end
		6'h09:begin type = 3'b001; end
		6'h0B:begin type = 3'b001; end
		6'h0C:begin type = 3'b001; end
		6'h0E:begin type = 3'b001; end
		6'h10:begin type = 3'b001; end
		6'h1C:begin type = 3'b001; end
		6'h12:begin type = 3'b001; end
		6'h13:begin type = 3'b001; end
		6'h14:begin type = 3'b110; end	//setbit
		6'h15:begin type = 3'b110; end //nsetbit
		
//branch stuff
		6'h23:  begin type = 3'b100; end
		6'h24:	 begin type = 3'b100; end
		6'h25:		begin type = 3'b100; end
	
//other 
		6'h30:begin type = 3'b001; end  //rri (ld)
		6'h31:begin type = 3'b111; end		//store
		6'h32:begin type = 3'b001; end		//ri (in)
		6'h33:begin type = 3'b111; end  //out


//jump stuff
		6'h20:  begin type = 3'b101; end		
		6'h21:  begin type = 3'b101; end
		6'h22:  begin type = 3'b101; end
		
		6'h16:begin type = 3'b010; end  //type RI
		6'h19:begin type = 3'b010; end
		6'h0D:begin type = 3'b011; end		//type special
		6'h11:begin type = 3'b011; end
		default: begin type = 3'b111; end
	endcase
	




	case(type)
		3'b000:		//RRR type
					begin
					Rd0_id = Iword[15:11];
					Rd1_id = Iword[10:6];
					Imm = 16'b0;
					Wr_id = Iword[20:16];
					end

		3'b001:		//RRI type
					begin
					Rd0_id = Iword[15:11];
					Rd1_id = 5'b0;
					Imm = {{8{Iword[7]}},Iword[7:0]};//?//
					Wr_id = Iword[20:16];
					end
		3'b010:		//RI type
					begin
					Rd0_id = 5'b0;
					Rd1_id = 5'b0;
					Imm = Iword[15:0];
					Wr_id = Iword[20:16];
					end
		3'b011:		//daa/shift type
					begin
					Rd0_id = Iword[15:11];
					Rd1_id = 5'b01101;		//flags register
					Imm = {{8{Iword[7]}},Iword[7:0]};//?//
					Wr_id = Iword[20:16];
					end
		3'b100:		//branch  RRI type
					begin 
					Rd0_id = Iword[20:16];
					Rd1_id = Iword[15:11];
					if (Iword[26:21] == 6'h23) Imm = 16'b0;
					else Imm = {{8{Iword[7]}},Iword[7:0]};
					Wr_id = 5'b0;
					end

		3'b101:
					begin
					if (Iword[26:21] == 6'h20) Rd0_id = 5'b0;
					else 	Rd0_id = Iword[20:16];
					Rd1_id = 5'b0;
					if (Iword[26:21] == 6'h21) Imm = 16'b0;
					else Imm = Iword[15:0];
					Wr_id = 5'b0; 
					end

		3'b110:
					begin
					Rd0_id = Iword[20:16];
					Rd1_id = Iword[15:11];
					Imm = {{8{Iword[7]}},Iword[7:0]};
					Wr_id = Iword[20:16];					
					end

		3'b111:		//store, out
					begin 
					Rd0_id = Iword[15:11];
					Rd1_id = Iword[20:16];
					Imm = {{8{Iword[7]}},Iword[7:0]};
					Wr_id = 5'b0;
					end

		default:
					begin
					Rd0_id = 5'b0;
					Rd1_id = 5'b0;
					Imm = 16'b0;
					Wr_id = 5'b0;
					end
	endcase

end//always
endmodule