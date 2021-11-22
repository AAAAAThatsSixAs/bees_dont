import rv32i_types::*;

module buffer_reg_MEM_WB
(
	input clk,
	input logic stall,
	input logic clear,
	
	input rv32i_control_word MEM_ctrlword,
	output rv32i_control_word WB_ctrlword,
	input rv32i_word MEM_pc,
	output rv32i_word WB_pc_plus_four,
//	input rv32i_word MEM_memdata,
//	output rv32i_word WB_memdata,
	input rv32i_word MEM_aluout,
	output rv32i_word WB_aluout,
	input logic MEM_cmpout,
	output rv32i_word WB_zextcmpout,
	input logic [4:0] MEM_rd_num,
	output logic [4:0] WB_rd_num,
	input logic MEM_memaccess,
	output logic WB_memaccess,

	// new stuff for forwarding
	input rv32i_reg MEM_rs1_num,
	output rv32i_reg WB_rs1_num,
	input rv32i_reg MEM_rs2_num,
	output rv32i_reg WB_rs2_num
);

register #(.width(28)) MEM_WB_ctrlword_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {28'b0} : MEM_ctrlword),
	.out(WB_ctrlword)
);
register MEM_WB_pc_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : MEM_pc+4),
	.out(WB_pc_plus_four)
);
//register MEM_WB_memdata_reg
//(
//	.clk,
//	.load(!stall),
//	.in(clear ? {32'b0} : MEM_memdata),
//	.out(WB_memdata)
//);
register MEM_WB_aluout_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : MEM_aluout),
	.out(WB_aluout)
);
register MEM_WB_zextcmpout_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : {31'h0000, MEM_cmpout}),
	.out(WB_zextcmpout)
);
register #(.width(5)) MEM_WB_rd_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {5'b0} : MEM_rd_num),
	.out(WB_rd_num)
);
register #(.width(1)) MEM_WB_memaccess_reg
(
    .clk,
    .load(!stall),
    .in(clear ? {1'b0} : MEM_memaccess),
    .out(WB_memaccess)
);

register #(.width(5)) rs1_num_reg
(
	.clk,
	.load(!stall),
	.in(MEM_rs1_num),
	.out(WB_rs1_num)
);

register #(.width(5)) rs2_num_reg
(
	.clk,
	.load(!stall),
	.in(MEM_rs2_num),
	.out(WB_rs2_num)
);

endmodule : buffer_reg_MEM_WB