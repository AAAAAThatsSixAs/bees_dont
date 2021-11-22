import rv32i_types::*;

module buffer_reg_ID_EX
(
	input clk,
	input logic stall,
	input logic clear,
	
	input rv32i_control_word ID_ctrlword,
	output rv32i_control_word EX_ctrlword,
	input rv32i_word ID_pc,
	output rv32i_word EX_pc,
	input rv32i_word ID_instr,
	output rv32i_word EX_instr,
	input rv32i_word ID_rs1,
	output rv32i_word EX_rs1,
	input rv32i_word ID_rs2,
	output rv32i_word EX_rs2,
	input logic [4:0] ID_rd_num,
	output logic [4:0] EX_rd_num,

	// new stuff for forwarding
	input rv32i_reg ID_rs1_num,
	output rv32i_reg EX_rs1_num,
	input rv32i_reg ID_rs2_num,
	output rv32i_reg EX_rs2_num
);

register #(.width(28)) ID_EX_ctrlword_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {28'b0} : ID_ctrlword),
	.out(EX_ctrlword)
);
register ID_EX_pc_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : ID_pc),
	.out(EX_pc)
);
register ID_EX_instr_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : ID_instr),
	.out(EX_instr)
);
register ID_EX_rs1_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : ID_rs1),
	.out(EX_rs1)
);
register ID_EX_rs2_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : ID_rs2),
	.out(EX_rs2)
);
register #(.width(5)) ID_EX_rd_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {5'b0} : ID_rd_num),
	.out(EX_rd_num)
);

// new stuff for forwarding

register #(.width(5)) rs1_num_reg
(
	.clk,
	.load(!stall),
	.in(ID_rs1_num),
	.out(EX_rs1_num)
);

register #(.width(5)) rs2_num_reg
(
	.clk,
	.load(!stall),
	.in(ID_rs2_num),
	.out(EX_rs2_num)
);

endmodule : buffer_reg_ID_EX