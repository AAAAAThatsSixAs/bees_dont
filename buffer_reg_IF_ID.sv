import rv32i_types::*;

module buffer_reg_IF_ID
(
	input clk,
	input logic stall,
	input logic clear,
	input rv32i_word IF_pc,
	output rv32i_word ID_pc,
//	input rv32i_word IF_instr,
//	output rv32i_word ID_instr,
	input logic IF_memaccess,
	output logic ID_memaccess
);

register IF_ID_pc_reg
(
	.clk,
	.load(!stall),
	.in(clear ? {32'b0} : IF_pc),
	.out(ID_pc)
);

//register IF_ID_instr_reg	
//(
//	.clk,
//	.load(!stall),
//	.in(clear ? {32'b0} : IF_instr),
//	.out(ID_instr)
//);

register #(.width(1)) IF_ID_memaccess_reg
(
    .clk,
    .load(!stall),
    .in(clear ? {1'b0} : IF_memaccess),
    .out(ID_memaccess)
);
endmodule : buffer_reg_IF_ID