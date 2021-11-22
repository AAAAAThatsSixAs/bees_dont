import rv32i_types::*;

module forward_MEM_EX
(
	// register numbers needed for forwarding
	input rv32i_reg MEM_rd_num,
	input rv32i_reg EX_rs1_num,
	input rv32i_reg EX_rs2_num,

	// to determine if loading regfile
	input rv32i_control_word MEM_ctrlword,
	input rv32i_control_word EX_ctrlword,

	// data in regs before forwarding
	input rv32i_word EX_rs1_data,
	input rv32i_word EX_rs2_data,
	input rv32i_word MEM_rd_data,

	// data after forwarding calculation
	output rv32i_word forward_EX_rs1,
	output rv32i_word forward_EX_rs2,
	output logic MEM_is_forwarding1,
	output logic MEM_is_forwarding2

);

always_comb
begin

	// default no change to rs1, rs2
	forward_EX_rs1 = EX_rs1_data;
	forward_EX_rs2 = EX_rs2_data;
	MEM_is_forwarding1 = 0;
	MEM_is_forwarding2 = 0;

	// rs1 check
	if ( MEM_ctrlword.load_regfile && EX_rs1_num && MEM_rd_num && EX_rs1_num == MEM_rd_num )
	begin
		forward_EX_rs1 = MEM_rd_data;
		MEM_is_forwarding1= 1;
	end

	// rs2 check
	if ( MEM_ctrlword.load_regfile && EX_rs2_num && MEM_rd_num && EX_rs2_num == MEM_rd_num && EX_ctrlword.opcode != op_imm )
	begin
		forward_EX_rs2 = MEM_rd_data;
		MEM_is_forwarding2 = 1;
	end
	
end

endmodule : forward_MEM_EX