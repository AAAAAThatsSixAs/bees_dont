module arbiter
(
	input clk,
	
	/* signals to/from L1 caches */
	output logic icache_resp,
	output logic dcache_resp,
	output [255:0] icache_rdata,
	output [255:0] dcache_rdata,
	input [255:0] dcache_wdata,
	input [31:0] icache_address,
	input [31:0] dcache_address,
	input logic icache_read,
	input logic dcache_read,
	input logic dcache_write,
	
	/* signals to/from L2 cache */
	input logic mem_resp,
	input [255:0] mem_rdata,
	output [255:0] mem_wdata,
	output [31:0] mem_address,
	output logic mem_read,
	output logic mem_write
);

logic mux_sel;

/* controller logic */
arbiter_control arbiter_control
(
	.clk,
	.dcache_read,
	.dcache_write,
	.icache_read,
	.mem_resp,
   .mux_sel
);

/* mux/demux logic */
assign icache_resp = mux_sel? 1'b0 : mem_resp;
assign dcache_resp = mux_sel? mem_resp : 1'b0;
assign icache_rdata = mux_sel? 0 : mem_rdata;
assign dcache_rdata = mux_sel? mem_rdata : 0; 
assign mem_wdata = dcache_wdata;

mux2 address_mux
(
	.sel(mux_sel),
	.a(icache_address),
	.b(dcache_address),
	.f(mem_address)
);
mux2 #(.width(1)) read_mux
(
	.sel(mux_sel),
	.a(icache_read),
	.b(dcache_read),
	.f(mem_read)
);
mux2 #(.width(1)) write_mux
(
	.sel(mux_sel),
	.a(1'b0),
	.b(dcache_write),
	.f(mem_write)
);

endmodule : arbiter