module daa_flags_out(add_in,add_flags,n_in,carry_in,flags_out);

input [15:0] add_in;
input [7:0] add_flags;
input carry_in;
input n_in;
output [7:0] flags_out;

reg [7:0] flags_out;
reg par;

always@(add_flags or carry_in or add_in or n_in)
begin
par=~^(add_in);
flags_out={add_flags[7:3],par,n_in,carry_in};
end
endmodule