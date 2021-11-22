module l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input logic mem_read,
	input logic mem_write,
	input logic [31:0] mem_address,
	input logic [255:0] mem_wdata,
	output logic [255:0] mem_rdata,
	output logic mem_resp,
	output logic pmem_read,
	output logic pmem_write,
	output logic [31:0] pmem_address,
	output logic [255:0] pmem_wdata,
	input logic [255:0] pmem_rdata,
	input logic pmem_resp
);

logic lru_read;
logic lru_load;
logic valid_read;
logic [3:0] valid_load;
logic dirty_read;
logic [3:0] dirty_load;
logic [3:0] dirty_in;
logic is_dirty;
logic [3:0] dirty_out;
logic tag_read;
logic [3:0] tag_load;
logic line_read;
logic load_filldata;
logic hit;
logic hit0;
logic hit1;
logic hit2;
logic hit3;
logic [1:0] lru_out;
logic compare_read;
logic pmem_addr_muxsel;
logic mbe_sel;
logic [3:0] mbe_way_sel;

l2_cache_datapath datapath
(
	.*
);

l2_cache_control control
(
	.*
);

endmodule : l2_cache
