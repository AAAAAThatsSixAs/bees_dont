import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module mp3
(
	input clk,
	
/*
	 output logic mem_read_a,
	 output logic [31:0] mem_address_a,
	 input logic mem_resp_a,
	 input logic [31:0] mem_rdata_a,

	 output logic mem_read_b,
	 output logic mem_write_b,
	 output logic [3:0] mem_wmask_b,
	 output logic [31:0] mem_address_b,
	 output logic [31:0] mem_wdata_b,
	 input logic mem_resp_b,
	 input logic [31:0] mem_rdata_b
		*/

	output logic pmem_read, 
	output logic pmem_write, 
	output rv32i_word pmem_address,
	output rv32i_line pmem_wdata,
	
	input logic pmem_resp,
	input rv32i_line pmem_rdata

);	


/* Memory signals */

/* CPU <-> icache */
logic mem_read_a;
logic [31:0] mem_address_a;
logic mem_resp_a;
logic [31:0] mem_rdata_a;
logic mem_stall_a;
logic mem_clear_a;

/* CPU <-> dcache */
logic mem_read_b;
logic mem_write_b;
logic [3:0] mem_wmask_b;
logic [31:0] mem_address_b;
logic [31:0] mem_wdata_b;
logic mem_resp_b;
logic [31:0] mem_rdata_b;
logic mem_stall_b;

/* icache <-> arbiter */
logic arb_icache_resp;
rv32i_line arb_icache_rdata;
logic [31:0] arb_icache_address;
logic arb_icache_read;

/* dcache <-> arbiter */
logic arb_dcache_resp;
rv32i_line arb_dcache_rdata;
rv32i_line arb_dcache_wdata;
logic [31:0] arb_dcache_address;
logic arb_dcache_read;
logic arb_dcache_write;

/* arbiter <-> L2 cache */
logic arb_l2cache_read;
logic arb_l2cache_write; 
rv32i_word arb_l2cache_address;
logic [255:0] arb_l2cache_wdata;
logic arb_l2cache_resp;
logic [255:0] arb_l2cache_rdata;

/* CPU */
pipelined_cpu cpu
(
	.clk,
	
	/* icache */
	.mem_read_a,
	.mem_address_a,
	.mem_resp_a,
	.mem_rdata_a,
	.mem_stall_a,
	.mem_clear_a,
	
	/* dcache */
	.mem_read_b,
	.mem_write_b,
	.mem_wmask_b,
	.mem_address_b,
	.mem_wdata_b,
	.mem_resp_b,
	.mem_rdata_b,
	.mem_stall_b
);	

/* L1 caches */
cache icache
(
	.clk,
	.mem_read(mem_read_a),
	.mem_write(1'b0), 
	.mem_byte_enable(4'b1111),			// is this correct
	.mem_address(mem_address_a),
	.mem_wdata(32'b0),						// okay to  hardcode to 0?
	.mem_rdata(mem_rdata_a),
	.mem_resp(mem_resp_a),
	.pmem_read(arb_icache_read),
	.pmem_write(),
	.pmem_address(arb_icache_address),
	.pmem_wdata(),
	.pmem_rdata(arb_icache_rdata),
	.pmem_resp(arb_icache_resp),
	.cpu_stall(mem_stall_a),
	.clear(mem_clear_a)
);

cache dcache
(
	.clk,
	.mem_read(mem_read_b),
	.mem_write(mem_write_b), 
	.mem_byte_enable(mem_wmask_b),				
	.mem_address(mem_address_b),
	.mem_wdata(mem_wdata_b),						
	.mem_rdata(mem_rdata_b),
	.mem_resp(mem_resp_b),
	.pmem_read(arb_dcache_read),
	.pmem_write(arb_dcache_write),
	.pmem_address(arb_dcache_address),
	.pmem_wdata(arb_dcache_wdata),
	.pmem_rdata(arb_dcache_rdata),
	.pmem_resp(arb_dcache_resp),
	.cpu_stall(mem_stall_b),
	.clear(1'b0)
);

/* Arbiter */
arbiter arbiter
(
	.clk,
	.icache_resp(arb_icache_resp),
	.dcache_resp(arb_dcache_resp),
	.icache_rdata(arb_icache_rdata),
	.dcache_rdata(arb_dcache_rdata),
	.dcache_wdata(arb_dcache_wdata),
	.icache_address(arb_icache_address),
	.dcache_address(arb_dcache_address),
	.icache_read(arb_icache_read),
	.dcache_read(arb_dcache_read),
	.dcache_write(arb_dcache_write),
	
	.mem_resp(pmem_resp),
	.mem_rdata(pmem_rdata),
	.mem_wdata(pmem_wdata),
	.mem_address(pmem_address),
	.mem_read(pmem_read),
	.mem_write(pmem_write)
	
	/*
	.mem_resp(arb_l2cache_resp),
	.mem_rdata(arb_l2cache_rdata),
	.mem_wdata(arb_l2cache_wdata),
	.mem_address(arb_l2cache_address),
	.mem_read(arb_l2cache_read),
	.mem_write(arb_l2cache_write)
	*/
);
	
/* L2 Cache */
/*
l2_cache	l2cache
(
	.clk,
	.mem_read(arb_l2cache_read),
	.mem_write(arb_l2cache_write), 			
	.mem_address(arb_l2cache_address),
	.mem_wdata(arb_l2cache_wdata),						
	.mem_rdata(arb_l2cache_rdata),
	.mem_resp(arb_l2cache_resp),
	.pmem_read,
	.pmem_write,
	.pmem_address,
	.pmem_wdata,
	.pmem_rdata,
	.pmem_resp
);
*/	
endmodule : mp3
