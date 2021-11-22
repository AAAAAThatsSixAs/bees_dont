import rv32i_types::*;

module forward_WB_EX
(
	input logic MEM_is_forwarding1,
	input logic MEM_is_forwarding2,

	// register numbers needed for forwarding
	input rv32i_reg WB_rd_num,
	input rv32i_reg EX_rs1_num,
	input rv32i_reg EX_rs2_num,

	// to determine if loading regfile
	input rv32i_control_word WB_ctrlword,
	input rv32i_control_word EX_ctrlword,

	// data in regs before forwarding
	input rv32i_word EX_rs1_data,
	input rv32i_word EX_rs2_data,
	input rv32i_word WB_rd_data,

	// data after forwarding calculation
	output rv32i_word forward_EX_rs1,
	output rv32i_word forward_EX_rs2

);

always_comb
begin

	// default not forwarding
	forward_EX_rs1 = EX_rs1_data;
	forward_EX_rs2 = EX_rs2_data;

	// rs1 check
	if ( WB_ctrlword.load_regfile && EX_rs1_num && WB_rd_num && EX_rs1_num == WB_rd_num && MEM_is_forwarding1 == 0 )
		forward_EX_rs1 = WB_rd_data;

	// rs2 check
	if ( WB_ctrlword.load_regfile && EX_rs2_num && WB_rd_num && EX_rs2_num == WB_rd_num && MEM_is_forwarding2 == 0 && EX_ctrlword.opcode != op_imm  )
		forward_EX_rs2 = WB_rd_data;

end

endmodule : forward_WB_EX