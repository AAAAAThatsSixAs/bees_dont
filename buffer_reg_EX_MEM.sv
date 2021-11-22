import rv32i_types::*;

module buffer_reg_EX_MEM
(
	input clk,
	input logic stall,
	input logic clear,
	
	input rv32i_control_word EX_ctrlword,
	output rv32i_control_word MEM_ctrlword,
	input rv32i_word EX_pc,
	output rv32i_word MEM_pc,
	input rv32i_word EX_aluout,
	output rv32i_word MEM_aluout,
	input rv32i_word EX_rs2,
	output rv32i_word MEM_rs2,
	input logic EX_cmpout,
	output logic MEM_cmpout,
	input logic [4:0] EX_rd_num,
	output logic [4:0] MEM_rd_num,

	// new stuff for forwarding
	input rv32i_reg EX_rs1_num,
	output rv32i_reg MEM_rs1_num,
	input rv32i_reg EX_rs2_num,
	output rv32i_reg MEM_rs2_num
);

register #(.width(28)) EX_MEM_ctrlword_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {28'b0} : EX_ctrlword),
	.out(MEM_ctrlword)
);
register EX_MEM_pc_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : EX_pc),
	.out(MEM_pc)
);
register EX_MEM_aluout_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : EX_aluout),
	.out(MEM_aluout)
);
register EX_MEM_rs2_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : EX_rs2),
	.out(MEM_rs2)
);
register #(.width(1)) EX_MEM_cmpout_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {1'b0} : EX_cmpout),
	.out(MEM_cmpout)
);
register #(.width(5)) EX_MEM_rd_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {5'b0} : EX_rd_num),
	.out(MEM_rd_num)
);

// new stuff for forwarding

register #(.width(5)) rs1_num_reg
(
	.clk,
	.load(!stall),
	.in(EX_rs1_num),
	.out(MEM_rs1_num)
);

register #(.width(5)) rs2_num_reg
(
	.clk,
	.load(!stall),
	.in(EX_rs2_num),
	.out(MEM_rs2_num)
);

endmodule : buffer_reg_EX_MEM