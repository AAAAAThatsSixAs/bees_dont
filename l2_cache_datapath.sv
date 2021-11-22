
module l2_cache_datapath #(
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
	input logic valid_read,
	input logic [3:0] valid_load,
	input logic line_read,
	input logic dirty_read,
	input logic [3:0] dirty_load,
	input logic tag_read,
	input logic [3:0] tag_load,
	input logic lru_load,
	input logic [3:0] dirty_in,
	input logic [3:0] mbe_way_sel,
	input logic load_filldata,
	input logic pmem_addr_muxsel,
	input logic compare_read,
	output logic is_dirty,
	output logic hit0,
	output logic hit1,
	output logic hit2,
	output logic hit3,
	output logic hit,
	output logic [1:0] lru_out,
	//memory
	input logic mem_read,
	input logic mem_write,
	input logic [31:0] mem_address,
	input logic [255:0] mem_wdata,
	output logic [255:0] mem_rdata,
	output logic [31:0] pmem_address,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata
);

logic [255:0] line_data[3:0];	//[2] vs [1:0]
logic [255:0] line_datahit;
logic [23:0] tag_regdata;
logic [255:0] fill_data_out;
logic [95:0] tag_out;
logic [3:0] valid_out;
logic [3:0] dirty_out;
logic [127:0] mbe_final;
logic [31:0] pmem_addr_b;
logic [1:0] hitmuxsel_out;

assign hit0 = (valid_out[0] && compare_read)? mem_address[31:8] == tag_out[23:0] : 1'b0;
assign hit1 = (valid_out[1] && compare_read)? mem_address[31:8] == tag_out[47:24] : 1'b0;
assign hit2 = (valid_out[2] && compare_read)? mem_address[31:8] == tag_out[71:48] : 1'b0;
assign hit3 = (valid_out[3] && compare_read)? mem_address[31:8] == tag_out[95:72] : 1'b0;
assign hit = hit0 || hit1 || hit2 || hit3;
assign is_dirty = dirty_out[0] || dirty_out[1] || dirty_out[2] || dirty_out[3];	
assign mem_rdata = line_datahit;

mux2 #(256) fill_data
(
	.sel(load_filldata),
	.a(mem_wdata),
	.b(pmem_rdata),
	.f(fill_data_out)
);

mux2 mbe0_mux
(
	.sel(mbe_way_sel[0]),	
	.a(32'b0),
	.b({32{1'b1}}),
	.f(mbe_final[31:0])
);

mux2 mbe1_mux
(
	.sel(mbe_way_sel[1]),
	.a(32'b0),
	.b({32{1'b1}}),
	.f(mbe_final[63:32])
);

mux2 mbe2_mux
(
	.sel(mbe_way_sel[2]),	
	.a(32'b0),
	.b({32{1'b1}}),
	.f(mbe_final[95:64])
);

mux2 mbe3_mux
(
	.sel(mbe_way_sel[3]),
	.a(32'b0),
	.b({32{1'b1}}),
	.f(mbe_final[127:96])
);

l2_data_array line [3:0]
(
	.clk,
	.read(line_read),
   .write_en(mbe_final),	//64 bits, upper 32 for way1, lower 32 for way0
   .index(mem_address[7:5]),
   .datain(fill_data_out),	//256 bits
	 //output
   .dataout(line_data)	
);

l2_array valid [3:0]
(
	.clk,
	.read(valid_read),
   .load(valid_load),
   .index(mem_address[7:5]),
   .datain(4'b1111),
   .dataout(valid_out)
);

l2_array dirty [3:0]
(
	.clk,
	.read(dirty_read),
   .load(dirty_load),
   .index(mem_address[7:5]),
   .datain(dirty_in),
   .dataout(dirty_out)
);

l2_array #(.width(24)) tag [3:0]
(
	.clk,
	.read(tag_read),
   .load(tag_load),
   .index(mem_address[7:5]),
   .datain(mem_address[31:8]),
   .dataout(tag_out)
);

lru_4way_l2 lru
(
	.clk,
	.lru_read(lru_read),
   .lru_load(lru_load),
   .index(mem_address[7:5]),
   .hit({hit0, hit1, hit2, hit3}),	
   .lru_out(lru_out)
);

mux4 #(.width(256)) missmux
(
	.sel(lru_out),
	.in0(line_data[0]),
	.in1(line_data[1]),
	.in2(line_data[2]),
	.in3(line_data[3]),
	.out(pmem_wdata)
);

mux4 #(.width(256)) hitmux
(
	.sel(hitmuxsel_out),	//array order
	.in0(line_data[0]),
	.in1(line_data[1]),
	.in2(line_data[2]),
	.in3(line_data[3]),
	.out(line_datahit)
);

case4 hitmux_sel
(
	.sel({hit0, hit1, hit2, hit3}),	
	.in0(2'b00),
	.in1(2'b01),
	.in2(2'b10),
	.in3(2'b11),
	.out(hitmuxsel_out)
);

mux4 pmem_addr_b_mux
(
	.sel(lru_out),	
	.in0({tag_out[23:0], mem_address[7:5], 5'b0}),
	.in1({tag_out[47:24], mem_address[7:5], 5'b0}),
	.in2({tag_out[71:48], mem_address[7:5], 5'b0}),
	.in3({tag_out[95:72], mem_address[7:5], 5'b0}),
	.out(pmem_addr_b)
);

mux2 pmem_addr_mux
(
	.sel(pmem_addr_muxsel),
	.a({mem_address[31:5], 5'b0}),
	.b(pmem_addr_b),
	.f(pmem_address)
);

endmodule : l2_cache_datapath

