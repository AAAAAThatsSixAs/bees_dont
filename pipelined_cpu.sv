import rv32i_types::*;

module pipelined_cpu
(
	input clk,

	/* FETCH (icache) */
	output mem_read_a,
	output [31:0] mem_address_a,
	input mem_resp_a,
	input [31:0] mem_rdata_a,
	output mem_stall_a,
	output logic mem_clear_a,

	/* MEM (dcache) */
	output mem_read_b,
	output mem_write_b,
	output [3:0] mem_wmask_b,
	output [31:0] mem_address_b,
	output [31:0] mem_wdata_b,
	input mem_resp_b,
	input [31:0] mem_rdata_b,
	output mem_stall_b
);

/* Signal declarations */

/* FETCH STAGE (IF) DECLARATIONS */
rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word alu_out_nolowestbit;

/* DECODE STAGE (ID) DECLARATIONS */
rv32i_word icache_rdata;
rv32i_word ID_pc;
//rv32i_word ID_instr;
logic ID_memaccess;
rv32i_control_word ctrl_word;
rv32i_reg rs1_num;
rv32i_reg rs2_num;
rv32i_reg rd_num;
rv32i_word rs1_data;
rv32i_word rs2_data;
rv32i_word ID_rs1;
rv32i_word ID_rs2;

/* EXECUTE STAGE (EX) DECLARATIONS */
rv32i_control_word EX_ctrlword;
rv32i_word EX_pc;
rv32i_word EX_instr;
rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;
rv32i_word EX_rs1;
rv32i_word EX_rs2;
rv32i_reg EX_rd_num;
rv32i_word alu_out;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmpmux_out;
logic cmpout;
rv32i_word EX_rs1_final;
rv32i_word EX_rs2_final;


/* MEMORY STAGE (MEM) DECLARATIONS */
rv32i_control_word MEM_ctrlword;
rv32i_word MEM_pc;
rv32i_word MEM_aluout;
rv32i_word MEM_rs2;
logic MEM_cmpout;
rv32i_reg MEM_rd_num;
logic[1:0] pcmux_sel;
rv32i_word MEM_rs2_final;

/* WRITEBACK STAGE (WB) DECLARATIONS */
rv32i_word dcache_rdata;
rv32i_control_word WB_ctrlword;
rv32i_word WB_pc_plus_four;
rv32i_word WB_rdata;
rv32i_word WB_aluout;
rv32i_word WB_zextcmpout;
rv32i_reg WB_rd_num;
logic WB_load_regfile;
logic WB_memaccess;
rv32i_word wbmux_out;

/* Forwarding-related signals */
rv32i_reg EX_rs1_num;
rv32i_reg MEM_rs1_num;
rv32i_reg WB_rs1_num;
rv32i_reg EX_rs2_num;
rv32i_reg MEM_rs2_num;
rv32i_reg WB_rs2_num;
rv32i_word rs1_data_tmp, rs2_data_tmp;
rv32i_word EX_rs2_tmp;

logic MEM_is_forwarding1;
logic MEM_is_forwarding2;
rv32i_word rs1_data1;
rv32i_word rs2_data1;
rv32i_word rs1_data2;
rv32i_word rs2_data2;

/* Double-hazard check */
logic MEM_EX_doublehazard;
assign MEM_EX_doublehazard = ((((MEM_rd_num == EX_rs1_num) || (MEM_rd_num == EX_rs2_num)) && MEM_rd_num) && (MEM_ctrlword.opcode == op_load)); // QUESTION: TODO: ask about this, maybe extend logic?

/* Stall-related signals */
logic stall_IF_ID, stall_ID_EX, stall_EX_MEM, stall_MEM_WB;
assign stall_IF_ID = stall_ID_EX;	
assign stall_ID_EX = stall_EX_MEM || MEM_EX_doublehazard;
assign stall_EX_MEM = stall_MEM_WB; 
assign stall_MEM_WB = (WB_memaccess && !mem_resp_b ) || (ID_memaccess && !mem_resp_a);		
assign mem_stall_a = stall_IF_ID;
assign mem_stall_b = stall_MEM_WB;

/* Clear-related signals */
logic flush_pipeline;
assign flush_pipeline = pcmux_sel && 1'b1;		// when pcmux_sel is 1 or 2, this  means we're branching/jumping and need to clear registers

logic clear_IF_ID, clear_ID_EX, clear_EX_MEM, clear_MEM_WB;
assign clear_IF_ID = flush_pipeline;
assign mem_clear_a = clear_IF_ID;
assign clear_ID_EX = flush_pipeline;
assign clear_EX_MEM = flush_pipeline || MEM_EX_doublehazard;
assign clear_MEM_WB = 1'b0;		// currently, never clear this

/* ------------------------------------- FETCH STAGE (IF) ----------------------------------------- */
assign alu_out_nolowestbit = {MEM_aluout[31:1], 1'b0};
assign mem_address_a = pc_out;	
assign mem_read_a = 1'b1; 	// if cache returns in 1 cycle can we just do this?

/* PC register*/
mux4 pcmux
(
    .sel(pcmux_sel),	
    .in0(pc_out + 4),
    .in1(MEM_aluout),	
	.in2(alu_out_nolowestbit),
	.in3(),
    .out(pcmux_out)
);
pc_register pc
(
    .clk,
    .load(!stall_IF_ID),		
    .in(pcmux_out),
    .out(pc_out)
);

/* FETCH -> DECODE buffer register */
buffer_reg_IF_ID buffer_reg_IF_ID
(
	.clk,
	.stall(stall_IF_ID),
	.clear(clear_IF_ID),
	.IF_pc(pc_out),
	.ID_pc,
	.IF_memaccess(mem_read_a),
	.ID_memaccess
//	.IF_instr(mem_rdata_a),
//	.ID_instr
);

/* -------------------------------------- DECODE STAGE (ID) ----------------------------------------- */
assign icache_rdata = mem_resp_a ? mem_rdata_a : 32'b0; 
assign rs1_num = icache_rdata[19:15];
assign rs2_num = icache_rdata[24:20];
assign rd_num = icache_rdata[11:7];

/* CONTROL ROM */
control_rom control_rom
(
	.opcode(rv32i_opcode'(icache_rdata[6:0])),
	.funct3(icache_rdata[14:12]),
	.funct7(icache_rdata[31:25]),
	.ctrl(ctrl_word)
);

/* REGFILE */
regfile regfile
(
	.clk,
	.load(WB_load_regfile && (WB_rd_num != 0) && !stall_MEM_WB),	
	.in(wbmux_out),  			
	.src_a(rs1_num),
	.src_b(rs2_num),
	.dest(WB_rd_num),			
    .reg_a(rs1_data),
	.reg_b(rs2_data)
);

/* DECODE -> EXECUTE buffer register */
buffer_reg_ID_EX buffer_reg_ID_EX
(
	.clk,
	.stall(stall_ID_EX),
	.clear(clear_ID_EX),
	.ID_ctrlword(ctrl_word),
	.EX_ctrlword,
	.ID_pc,
	.EX_pc,
	.ID_instr(icache_rdata),
	.EX_instr,
	.ID_rs1,
	.EX_rs1,
	.ID_rs2,
	.EX_rs2,
	.ID_rd_num(rd_num),
	.EX_rd_num,

	.ID_rs1_num(rs1_num),
	.EX_rs1_num,
	.ID_rs2_num(rs2_num),
	.EX_rs2_num
);

/* WRITEBACK -> DECODE forwarding path */
forward_WB_ID forward_WB_ID
(
	.ID_rs1_num(rs1_num),
	.ID_rs2_num(rs2_num),
	.WB_rd_num,
	.WB_ctrlword,
	.ctrl_word,
	.ID_rs1_data(rs1_data),
	.ID_rs2_data(rs2_data),
	.WB_rd_data( wbmux_out ),
	.forward_ID_rs1(ID_rs1),
	.forward_ID_rs2(ID_rs2)
);

/* -------------------------------------- EXECUTE STAGE (EX) ----------------------------------------- */
assign i_imm = {{21{EX_instr[31]}}, EX_instr[30:20]};
assign s_imm = {{21{EX_instr[31]}}, EX_instr[30:25], EX_instr[11:7]};
assign b_imm = {{20{EX_instr[31]}}, EX_instr[7], EX_instr[30:25], EX_instr[11:8], 1'b0};
assign u_imm = {EX_instr[31:12], 12'h000};
assign j_imm = {{12{EX_instr[31]}}, EX_instr[19:12], EX_instr[20], EX_instr[30:21], 1'b0};
assign EX_rs1_final = MEM_is_forwarding1? rs1_data2 : rs1_data1;
assign EX_rs2_final = MEM_is_forwarding2? rs2_data2 : rs2_data1;
/* ALU */
mux2 alumux1
(
	.sel(EX_ctrlword.alumux1_sel),
	.a(EX_rs1_final),
	.b(EX_pc),
	.f(alumux1_out)
);
mux8 alumux2
(
	.sel(EX_ctrlword.alumux2_sel),
	.in0(i_imm),
	.in1(u_imm),
	.in2(b_imm),
	.in3(s_imm),
	.in4(j_imm),
	.in5(EX_rs2_final),
	.in6(),
	.in7(),
	.out(alumux2_out)
);
alu alu
(
	.aluop(EX_ctrlword.aluop),
	.a(alumux1_out),
	.b(alumux2_out),
    .f(alu_out)
);

/* CMP */
mux2 #(.width(32)) cmpmux
(
	.sel(EX_ctrlword.cmpmux_sel),
	.a(EX_rs2_final),
	.b(i_imm),
	.f(cmpmux_out)
);
cmp cmp
(
	.a(EX_rs1_final),
	.b(cmpmux_out),
	.result(cmpout),
    .cmpop(EX_ctrlword.cmpop)
);

/* EXECUTE -> MEM buffer register */
buffer_reg_EX_MEM  buffer_reg_EX_MEM
(
	.clk,
	.stall(stall_EX_MEM),
	.clear(clear_EX_MEM),
	.EX_ctrlword,
	.MEM_ctrlword,
	.EX_pc,
	.MEM_pc,
	.EX_aluout(alu_out),
	.MEM_aluout,
	.EX_rs2(EX_rs2_final),
	.MEM_rs2,
	.EX_cmpout(cmpout),
	.MEM_cmpout,
	.EX_rd_num,
	.MEM_rd_num,
	.EX_rs1_num,
	.MEM_rs1_num,
	.EX_rs2_num,
	.MEM_rs2_num
);

/* WRITEBACK -> EXECUTE forwarding path */
forward_WB_EX forward_WB_EX
(
	.MEM_is_forwarding1,
	.MEM_is_forwarding2,
	.EX_rs1_num,
	.EX_rs2_num,
	.WB_rd_num,
	.WB_ctrlword,
	.EX_ctrlword,
	.EX_rs1_data(EX_rs1),
	.EX_rs2_data(EX_rs2),
	.WB_rd_data( wbmux_out ),
	.forward_EX_rs1(rs1_data1),
	.forward_EX_rs2(rs2_data1)
);

/* MEMORY -> EXECUTE forwarding path */
forward_MEM_EX forward_MEM_EX
(
	// must add logic to ex that determines if forwarding from here or wb
	.MEM_is_forwarding1,
	.MEM_is_forwarding2,
	.EX_rs1_num,
	.EX_rs2_num,
	.MEM_rd_num,
	.MEM_ctrlword,
	.EX_ctrlword,
	.EX_rs1_data(EX_rs1),
	.EX_rs2_data(EX_rs2),
	.MEM_rd_data( MEM_aluout ),
	.forward_EX_rs1(rs1_data2),
	.forward_EX_rs2(rs2_data2)
);

/* -------------------------------------- MEMORY STAGE (MEM) ----------------------------------------- */
assign mem_address_b = MEM_aluout;
assign mem_read_b = MEM_ctrlword.mem_read;
assign mem_write_b = MEM_ctrlword.mem_write;

/* calculate pcmux select based off branch/jump instr */
mux4 #(.width(2)) brtype_mux
(
    .sel(MEM_ctrlword.brtype),
    .in0(2'h0),						// no branch or jump
    .in1(2'h1),						// jal
	.in2(2'h2),							// jalr
	.in3({1'h0, MEM_cmpout}),		// branch
    .out(pcmux_sel)
);

/* data alignment for memory writes */
dcache_wdata_aligner dcache_wdata_aligner
(
	.funct3(MEM_ctrlword.funct3),
	.mem_sel(MEM_aluout[1:0]),
	.unaligned_wdata(MEM_rs2_final),
	.aligned_wdata(mem_wdata_b),
	.mem_byte_enable(mem_wmask_b)
);


/* MEM -> WRITEBACK buffer register */
buffer_reg_MEM_WB  buffer_reg_MEM_WB
(
	.clk,
	.stall(stall_MEM_WB),
	.clear(clear_MEM_WB),
	.MEM_ctrlword,
	.WB_ctrlword,
	.MEM_pc,
	.WB_pc_plus_four,
//	.MEM_memdata(aligned_rdata),
//	.WB_memdata,
	.MEM_aluout,
	.WB_aluout,
	.MEM_cmpout,
	.WB_zextcmpout,
	.MEM_rd_num,
	.WB_rd_num,
	.MEM_memaccess(mem_read_b || mem_write_b),
	.WB_memaccess,
	.MEM_rs1_num,
	.WB_rs1_num,
	.MEM_rs2_num,
	.WB_rs2_num
);

/* WRITEBACK-> MEMORY forwarding path */
forward_WB_MEM forward_WB_MEM
(
	.MEM_rs2_num,
	.WB_rd_num,
	.WB_ctrlword,
	.MEM_ctrlword,
	.MEM_rs2_data(MEM_rs2),
	.WB_rd_data( wbmux_out ),
	.forward_MEM_rs2(MEM_rs2_final)
);

/* -------------------------------------- WRITEBACK STAGE (WB) ----------------------------------------- */
assign dcache_rdata = mem_resp_b ? mem_rdata_b : 32'b0; 
assign WB_load_regfile = WB_ctrlword.load_regfile;

dcache_rdata_aligner dcache_rdata_aligner
(
	.funct3(WB_ctrlword.funct3),
	.mem_sel(WB_aluout[1:0]),
	.unaligned_rdata(dcache_rdata),
	.aligned_rdata(WB_rdata)
);

/* Writeback time! */
mux4 wbmux
(
    .sel(WB_ctrlword.wbmux_sel),
    .in0(WB_pc_plus_four),
    .in1(WB_aluout),
	.in2(WB_rdata),	
	.in3(WB_zextcmpout),
    .out(wbmux_out)
);

endmodule : pipelined_cpu
