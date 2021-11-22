module mux16 #(parameter width = 32)
(
input [3:0] sel,
input [width-1:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15,
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
		8: out = in8;
		9: out = in9;
		10: out = in10;
		11: out = in11;
		12: out = in12;
		13: out = in13;
		14: out = in14;
		15: out = in15;
		default: $display("Unknown_16mux_in");
	endcase
end
endmodule : mux16