module daa(data_in,flags, add_op, carry_out,n_out);
input [7:0] data_in;
input [7:0] flags;

output [15:0] add_op;
output carry_out,n_out;


reg [15:0] add_op;
reg carry_out,n_out;


always@(data_in or flags)
begin
	if(flags[0]==1'b0 && data_in[7:4]<=4'b1001 && data_in[3:0]<=4'b1001 && flags[4]==1'b0)
		begin
		add_op=16'b0;
		carry_out=1'b0;
		n_out=flags[7];
		end	
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1000 && data_in[3:0]<=4'b1111 && data_in[3:0]>=4'b1010 && flags[4]==1'b0)
		begin
		add_op=16'h0006;
		carry_out=1'b0;
		n_out=flags[7];
		end
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1001 && data_in[3:0]<=4'b0011 && flags[4]==1'b1)
		begin
		add_op=16'h0006;
		carry_out=1'b0;
		n_out=flags[7];
		end
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1111 && data_in[7:4] >= 4'b1010 && data_in[3:0]<=4'b1001 && flags[4]==1'b0)
		begin
		add_op=16'h0060;
		carry_out=1'b1;
		n_out=flags[7];
		end
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1111 && data_in[7:4] >= 4'b1001 && data_in[3:0]<=4'b1111 && data_in[3:0]>=4'b1010 && flags[4]==1'b0)
		begin		
		add_op=16'h66;
		carry_out=1'b1;
		n_out=flags[7];
		end
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1111 && data_in[7:4] >= 4'b1010 && data_in[3:0]<=4'b0011 && flags[4]==1'b1)
		begin
		add_op=16'h0066;
		carry_out=1'b1;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b1 && data_in[7:4]<=4'b0010 && data_in[3:0]<=4'b1001 && flags[4]==1'b0)
		begin
		add_op=16'h0060;
		carry_out=1'b1;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b1 && data_in[7:4]<=4'b0010 && data_in[3:0]<=4'b1111 && data_in[3:0]>=4'b1010 && flags[4]==1'b0)
		begin
		add_op=16'h0066;
		carry_out=1'b1;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b1 && data_in[7:4]<=4'b0011 && data_in[3:0]<=4'b0011 && flags[4]==1'b1)
		begin
		add_op=16'h0066;
		carry_out=1'b1;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1001 && data_in[3:0]<=4'b1001 && flags[4]==1'b0)
		begin
		add_op=16'h0;
		carry_out=1'b0;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b0 && data_in[7:4]<=4'b1000 && data_in[3:0]<=4'b1111 && data_in[3:0]>=4'b0110 && flags[4]==1'b1)
		begin
		add_op=16'h00fa;
		carry_out=1'b0;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b1 && data_in[7:4]<=4'b1111 && data_in[7:4] >= 4'b0111 && data_in[3:0]<=4'b1001 && flags[4]==1'b0)
		begin
		add_op=16'h00a0;
		carry_out=1'b1;		
		n_out=flags[7];
		end
	else if(flags[0]==1'b1 && data_in[7:4]<=4'b0111 && data_in[7:4] >= 4'b0110 && data_in[3:0]<=4'b1111 && data_in[3:0]>=4'b0110 && flags[4]==1'b1)
		begin
		add_op=16'h009a;
		carry_out=1'b1;		
		n_out=flags[7];
		end

	else
	begin
	add_op=16'h00;	
	carry_out=1'b0;
	n_out=flags[7];
	end


end//always




endmodule


