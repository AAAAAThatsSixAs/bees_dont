module mux4 #(parameter width = 32)
(
input [1:0] sel,
input [width-1:0] in0, in1, in2, in3,
output logic [width-1:0] out
);
always_comb
begin
	case(sel)
		0: out = in0;
		1: out = in1;
		2: out = in2;
		3: out = in3;
		default: $display("Unknown_4mux_in");
	endcase
end
endmodule : mux4