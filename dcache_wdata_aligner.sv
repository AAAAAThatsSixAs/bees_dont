/* This module handles memory data-alignment for write operations */
import rv32i_types::*;
module dcache_wdata_aligner
(
	input logic[2:0] funct3,
	input logic[1:0] mem_sel,
	input rv32i_word unaligned_wdata,
	output rv32i_word aligned_wdata,
	output rv32i_mem_wmask mem_byte_enable
	
);

/* determine the alignment operations we need to perform */
store_funct3_t store_funct3;			// storing == writing 
assign store_funct3 = store_funct3_t'(funct3);

/* mem write data alignment */
always_comb
begin : wdata_aligner
	case(store_funct3)
		sb: begin 
			mem_byte_enable = 4'b0001 << mem_sel;
			aligned_wdata = {unaligned_wdata[7:0], unaligned_wdata[7:0], unaligned_wdata[7:0], unaligned_wdata[7:0]};
		end
		sh: begin 
			mem_byte_enable = 4'b0011 << mem_sel;
			aligned_wdata = {unaligned_wdata[15:0], unaligned_wdata[15:0]};
		end
		sw: begin 
			mem_byte_enable = 4'b1111;
			aligned_wdata = unaligned_wdata;
		end
	endcase
end

endmodule : dcache_wdata_aligner