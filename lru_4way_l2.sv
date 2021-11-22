module lru_4way_l2
(
	 input clk,
	 input logic lru_load,
	 input logic lru_read,
	 input logic[2:0] index,
	 input logic[3:0] hit,
	 output logic[1:0] lru_out
);

logic[2:0] pseudolru_in;
logic[2:0] pseudolru_out;

l2_array #(.width(3)) lru
(
	.clk,
	.read(lru_read || lru_load),
   .load(lru_load),
   .index(index),
   .datain(pseudolru_in),	
   .dataout(pseudolru_out)
);

always_comb
begin : pseudo_lru

	pseudolru_in = 3'b000;
	lru_out = 2'b00;

	if (lru_load)
		case(hit)
			8: pseudolru_in = {pseudolru_out[2], 2'b11};
			4: pseudolru_in = {pseudolru_out[2], 2'b01};
			2: pseudolru_in = {1'b1, pseudolru_out[1], 1'b0};
			1: pseudolru_in = {1'b0, pseudolru_out[1], 1'b0};
			0: pseudolru_in = pseudolru_out;
			default: $display("Erroneous hit signal");
		endcase
	
	if (lru_read)
		case(pseudolru_out[0])
			0: case(pseudolru_out[1])
					0: lru_out = 0;
					1: lru_out = 1;
				endcase
			1: case(pseudolru_out[2])
					0: lru_out = 2;
					1: lru_out = 3;
				endcase
		endcase
end

endmodule : lru_4way_l2
