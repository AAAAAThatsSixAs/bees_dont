module pipeline_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input logic lru_read,
	input logic [1:0] valid_read,
	input logic [1:0] valid_load,
	input logic [1:0] line_read,
	input logic [1:0] dirty_read,
	input logic [1:0] dirty_load,
	input logic [1:0] tag_read,
	input logic [1:0] tag_load,
	input logic lru_load,
	input logic [1:0] dirty_in,
	input logic mbe_sel,
	input logic [1:0] mbe_way_sel,
	input logic load_filldata,
	input logic pmem_addr_muxsel,
	input logic compare_read,
	input logic use_resp_addr,
	output logic is_dirty,
	output logic hit0,
	output logic hit1,
	output logic hit,
	output logic lru_out,
	input logic cache_stall,
	input logic clear,
	
	//memory
	input logic mem_read,
	input logic mem_write,
	input logic [3:0] mem_byte_enable,
	input logic [31:0] mem_address,
	input logic [31:0] mem_wdata,
	output logic [31:0] mem_rdata,
	output logic [31:0] pmem_address,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata
);

logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [255:0] line_data[1:0];	//[2] vs [1:0]
logic [255:0] line_datahit;
logic [23:0] tag_regdata;
logic [255:0] fill_data_out;
logic [31:0] mem_byte_enable256;
logic [47:0] tag_out;
logic [1:0] valid_out;
logic [1:0] dirty_out;
logic [63:0] mbe_final;
logic [31:0] mbe_out;
logic [31:0] mem_byte_enable256_out;
logic [31:0] mem_address_out;
logic [255:0] mem_wdata256_out;
logic [31:0] mem_addr;

assign hit0 = (valid_out[0] && compare_read)? mem_address_out[31:8] == tag_out[23:0] : 1'b0;
assign hit1 = (valid_out[1] && compare_read)? mem_address_out[31:8] == tag_out[47:24] : 1'b0;
assign hit = hit0 || hit1;
assign is_dirty = (dirty_out[lru_out] || dirty_out[!lru_out]);
assign mem_addr = use_resp_addr ? mem_address_out : mem_address;

register mbe_reg
(
    .clk,
    .load(!cache_stall),
    .in(mem_byte_enable256),
    .out(mem_byte_enable256_out)
);

register address_reg
(
    .clk,
    .load(!cache_stall),
    .in(mem_address),
    .out(mem_address_out)
);

register #(256) wdata_reg
(
    .clk,
    .load(!cache_stall),
    .in(mem_wdata256),
    .out(mem_wdata256_out)
);

mux2 #(256) fill_data
(
	.sel(load_filldata),
	.a(mem_wdata256_out),
	.b(pmem_rdata),
	.f(fill_data_out)
);

mux2 mbe_mux
(
	.sel(mbe_sel),
	.a(mem_byte_enable256_out),
	.b({32{1'b1}}),
	.f(mbe_out)
);

mux2 mbe0_mux
(
	.sel(mbe_way_sel[0]),	
	.a(32'b0),
	.b(mbe_out),
	.f(mbe_final[31:0])
);

mux2 mbe1_mux
(
	.sel(mbe_way_sel[1]),
	.a(32'b0),
	.b(mbe_out),
	.f(mbe_final[63:32])
);

data_array line [1:0]
(
	.clk,
	.read(line_read && !(cache_stall && hit)),
   .write_en(mbe_final),	//64 bits, upper 32 for way1, lower 32 for way0
   .rindex(mem_addr[7:5]),
   .windex(mem_address_out[7:5]),
   .datain(fill_data_out),	//256 bits
	 //output
   .dataout(line_data)	
);

array valid [1:0]
(
	.clk,
	.read(valid_read && !(cache_stall && hit)),
   .load(valid_load),
	.rindex(mem_addr[7:5]),
   .windex(mem_address_out[7:5]),
   .datain(2'b11),
   .dataout(valid_out)
);

array dirty [1:0]
(
	.clk,
	.read(dirty_read && !(cache_stall && hit)),
   .load(dirty_load),
   .rindex(mem_addr[7:5]),
   .windex(mem_address_out[7:5]),
   .datain(dirty_in),
   .dataout(dirty_out)
);

array #(.width(24)) tag [1:0]
(
	.clk,
	.read(tag_read && !(cache_stall && hit)),
   .load(tag_load),
   .rindex(mem_addr[7:5]),
   .windex(mem_address_out[7:5]),
   .datain(mem_address_out[31:8]),
   .dataout(tag_out)
);

array lru
(
	.clk,
	.read(lru_read && !(cache_stall && hit)),
   .load(lru_load),
   .rindex(mem_addr[7:5]),
   .windex(mem_address_out[7:5]),
   .datain(hit0 ? 1'b1 : 1'b0),	
   .dataout(lru_out)
);

mux2 #(.width(256)) missmux
(
	.sel(lru_out),
	.a(line_data[0]),
	.b(line_data[1]),
	.f(pmem_wdata)
);

mux2 #(.width(256)) hitmux
(
	.sel(hit1? 1'b1: 1'b0),	//array order
	.a(line_data[0]),
	.b(line_data[1]),
	.f(line_datahit)
);

mux2 pmem_addr_mux
(
	.sel(pmem_addr_muxsel),
	.a({mem_address_out[31:5], 5'b0}),
	.b({(lru_out? tag_out[47:24] : tag_out[23:0]), mem_address_out[7:5], 5'b0}),
	.f(pmem_address)
);

line_adapter bus_adapter
(
	.mem_wdata256,						//output
   .mem_rdata256(line_datahit),	//input
   .mem_wdata,							//input
   .mem_rdata,							//output
   .mem_byte_enable,					//input
   .mem_byte_enable256,				//output
	.resp_address(mem_address_out), //input
   .address(mem_addr)			//input
);

endmodule : pipeline_cache_datapath

