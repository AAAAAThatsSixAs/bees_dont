import rv32i_types::*;

module forward_WB_ID
(
	// register numbers needed for forwarding
	input rv32i_reg WB_rd_num,
	input rv32i_reg ID_rs1_num,
	input rv32i_reg ID_rs2_num,

	// to determine if loading regfile
	input rv32i_control_word WB_ctrlword,
	input rv32i_control_word ctrl_word,

	// data in regs before forwarding
	input rv32i_word ID_rs1_data,
	input rv32i_word ID_rs2_data,
	input rv32i_word WB_rd_data,

	// data after forwarding calculation
	output rv32i_word forward_ID_rs1,
	output rv32i_word forward_ID_rs2

);

always_comb
begin

	// default, not forwarding
	forward_ID_rs1 = ID_rs1_data;
	forward_ID_rs2 = ID_rs2_data;

	// rs1 check
	if ( WB_ctrlword.load_regfile && ID_rs1_num && WB_rd_num && ID_rs1_num == WB_rd_num )
		forward_ID_rs1 = WB_rd_data;

	// rs2 check
	if ( WB_ctrlword.load_regfile && ID_rs2_num && WB_rd_num && ID_rs2_num == WB_rd_num && ctrl_word.opcode != op_imm  )
		forward_ID_rs2 = WB_rd_data;

end

endmodule : forward_WB_ID