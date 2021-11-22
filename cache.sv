module cache #(
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
	input logic [3:0] mem_byte_enable,
	input logic [31:0] mem_address,
	input logic [31:0] mem_wdata,
	output logic [31:0] mem_rdata,
	output logic mem_resp,
	output logic pmem_read,
	output logic pmem_write,
	output logic [31:0] pmem_address,
	output logic [255:0] pmem_wdata,
	input logic [255:0] pmem_rdata,
	input logic pmem_resp,
	input logic cpu_stall,
	input logic clear
);

logic lru_read;
logic lru_load;
logic [1:0] valid_read;
logic [1:0] valid_load;
logic [1:0] dirty_read;
logic [1:0] dirty_load;
logic [1:0] dirty_in;
logic is_dirty;
logic [1:0] dirty_out;
logic [1:0] tag_read;
logic [1:0] tag_load;
logic [1:0] line_read;
logic load_filldata;
logic hit;
logic hit0;
logic hit1;
logic lru_out;
logic compare_read;
logic pmem_addr_muxsel;
logic mbe_sel;
logic [1:0] mbe_way_sel;
logic cache_stall;
logic use_resp_addr;

pipeline_cache_datapath datapath
(
	.*
);

pipeline_cache_control control
(
	.*
);

endmodule : cache
