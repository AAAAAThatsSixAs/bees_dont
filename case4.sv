module case4 
(
input [3:0] sel,
input [1:0] in0, in1, in2, in3,
output logic [1:0] out
);
always_comb
begin
	out = 0;
	case(sel)
		4'b1000: out = in0;
		4'b0100: out = in1;
		4'b0010: out = in2;
		4'b0001: out = in3;
		4'b0000: ;
		default: $display("Unknown_4case_in");
	endcase
end
endmodule : case4
