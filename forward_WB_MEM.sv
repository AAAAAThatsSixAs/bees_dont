import rv32i_types::*;

/* No rs1 */ 
module forward_WB_MEM
(
	// register numbers needed for forwarding
	input rv32i_reg WB_rd_num,
	input rv32i_reg MEM_rs2_num,

	// to determine if loading regfile
	input rv32i_control_word WB_ctrlword,
	input rv32i_control_word MEM_ctrlword,

	// data in regs before forwarding
	input rv32i_word MEM_rs2_data,
	input rv32i_word WB_rd_data,

	// data after forwarding calculation
	output rv32i_word forward_MEM_rs2

);

always_comb
begin
	// rs2 check
	if (WB_ctrlword.load_regfile && MEM_rs2_num && WB_rd_num && MEM_rs2_num == WB_rd_num && MEM_ctrlword.opcode != op_imm)
	begin
		forward_MEM_rs2 = WB_rd_data;
	end

	// not forwarding
	else
	begin
		// no change to rs2
		forward_MEM_rs2 = MEM_rs2_data;
	end
end

endmodule : forward_WB_MEM