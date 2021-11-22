module mux8 #(parameter width = 32)
(
input [2:0] sel,
input [width-1:0] in0, in1, in2, in3, in4, in5, in6, in7, 
output logic [width-1:0] out
);
always_comb
begin
	case(sel)
		0: out = in0;
		1: out = in1;
		2: out = in2;
		3: out = in3;
		4: out = in4;
		5: out = in5;
		6: out = in6;
		7: out = in7;
		default: $display("Unknown_8mux_in");
	endcase
end
endmodule : mux8