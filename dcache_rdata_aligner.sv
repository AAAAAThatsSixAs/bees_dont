/* This module handles memory data-alignment for read operations */
import rv32i_types::*;
module dcache_rdata_aligner
(
	input logic[2:0] funct3,
	input logic[1:0] mem_sel,
	input rv32i_word unaligned_rdata,
	output rv32i_word aligned_rdata
);


/* determine the alignment operations we need to perform */
load_funct3_t load_funct3;				// loading == reading
assign load_funct3 = load_funct3_t'(funct3);

/* mem read data alignment */
always_comb
begin : rdata_aligner
	case(load_funct3)
		 lw: aligned_rdata = unaligned_rdata;
		 lb: begin 
			case(mem_sel)		// QUESTION we need to figure out what's going on with mem_sel, do we even need it anymore?  does the cache alerady deal with it
				0: aligned_rdata = {{24{unaligned_rdata[7]}},unaligned_rdata[7:0]};
				1: aligned_rdata = {{24{unaligned_rdata[15]}},unaligned_rdata[15:8]};
				2: aligned_rdata = {{24{unaligned_rdata[23]}},unaligned_rdata[23:16]};
				3: aligned_rdata = {{24{unaligned_rdata[31]}},unaligned_rdata[31:24]};
			endcase
		 end
		 lh: begin 
			case(mem_sel)
				0: aligned_rdata = {{16{unaligned_rdata[15]}},unaligned_rdata[15:0]};
				2: aligned_rdata = {{16{unaligned_rdata[31]}},unaligned_rdata[31:16]};
				default: begin 
					aligned_rdata = 0;
					$display("Bad mem_sel (lh)");
				end 
			endcase 
		 end
		 lbu: begin 
			case(mem_sel)
				0: aligned_rdata = {24'h0000, unaligned_rdata[7:0]};
				1: aligned_rdata = {24'h0000, unaligned_rdata[15:8]};
				2: aligned_rdata = {24'h0000, unaligned_rdata[23:16]};
				3: aligned_rdata = {24'h0000, unaligned_rdata[31:24]};
			endcase
		 end
		 lhu: begin 
			case(mem_sel)
				0: aligned_rdata = {16'h0000, unaligned_rdata[15:0]};
				2: aligned_rdata = {16'h0000, unaligned_rdata[31:16]};
				default: begin
					aligned_rdata = 0;
					$display("Bad mem_sel (lhu)");
				end
			endcase 
		 end
	endcase
end

endmodule : dcache_rdata_aligner