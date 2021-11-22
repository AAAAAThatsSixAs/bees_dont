import rv32i_types::*;

module control_rom
(
	input rv32i_opcode opcode,
	input logic[2:0] funct3,
	input logic[6:0] funct7,
	output rv32i_control_word ctrl

	// new stuff for forwarding
	// input rv32i_reg _rs1,
	// input rv32i_reg _rs2
);

branch_funct3_t branch_funct3;
arith_funct3_t arith_funct3;

assign branch_funct3 = branch_funct3_t'(funct3);
assign arith_funct3 = arith_funct3_t'(funct3);

//TODO: mar, mdr, jump
always_comb
begin
	/* Default assignments */
	ctrl.opcode = opcode;
	ctrl.alumux1_sel = 0;	// rs1
	ctrl.alumux2_sel = 0;	// i_imm
	ctrl.cmpop = branch_funct3;
	ctrl.cmpmux_sel = 0;
	ctrl.aluop = alu_ops'(funct3);
	ctrl.funct3 = funct3;
	ctrl.brtype = 0; 			// 0=none, 1=jal, 2=jalr, 3=br
	ctrl.mem_read = 0;		// no mem read 
	ctrl.mem_write = 0;		// no mem write
	ctrl.wbmux_sel = 1;		// memdata
	ctrl.load_regfile = 0;	// no regfile load

	// new stuf for forwarding
	// ctrl.rs1 = _rs1;
	// ctrl.rs2 = _rs2;		
	
	/* Assign control signals based on opcode */
	case(opcode)
		op_imm: begin 
			ctrl.alumux2_sel = 0;
			ctrl.load_regfile = 1;
			case(arith_funct3)
				slt: begin 
					ctrl.cmpop = blt;
					ctrl.wbmux_sel = 3;
					ctrl.cmpmux_sel = 1;		
				end
				sltu: begin 
					ctrl.cmpop = bltu;
					ctrl.wbmux_sel = 3;
					ctrl.cmpmux_sel = 1;		
				end
				sr: begin 				
					case(funct7)
						7'b0000000: ctrl.aluop = alu_ops'(funct3);
						7'b0100000: ctrl.aluop = alu_sra;
						default: $display("Erroneous_funct7");
					endcase
				end
				default: ctrl.aluop = alu_ops'(funct3);
			endcase
		end
		op_br: begin
			ctrl.brtype = 3;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 2;
			ctrl.aluop = alu_add;
		end
		op_load: begin
			ctrl.aluop = alu_add;
			//mem
			ctrl.mem_read = 1;
			//wb
			ctrl.wbmux_sel = 2;	//dcache_readmux_out
			ctrl.load_regfile = 1;
			end
		op_store: begin
			//ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 3;
			ctrl.aluop = alu_add;
			ctrl.mem_write = 1;
			end
		op_auipc: begin
			ctrl.load_regfile = 1;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 1;
			ctrl.aluop = alu_add;
		end
		op_lui: begin
			ctrl.load_regfile = 1;
			ctrl.wbmux_sel = 1;	//u_imm
		end
		op_reg: begin
			ctrl.load_regfile = 1;
			ctrl.alumux2_sel = 5;
			case(arith_funct3)
				add: begin 
					case(funct7)
						7'b0100000: ctrl.aluop = alu_sub;
						default: ctrl.aluop = alu_ops'(funct3);
					endcase
				end
				slt: begin 
					ctrl.cmpop = blt;
					ctrl.wbmux_sel = 3;	//br_en
					ctrl.cmpmux_sel = 0;		
				end
				sltu: begin 
					ctrl.cmpop = bltu;
					ctrl.wbmux_sel = 3;	//br_en
					ctrl.cmpmux_sel = 0;		
				end
				sr: begin 		
					case(funct7)
						7'b0000000: ctrl.aluop = alu_ops'(funct3);
						7'b0100000: ctrl.aluop = alu_sra;
						default: $display("Erroneous_funct7");
					endcase
				end
				default: ctrl.aluop = alu_ops'(funct3);
			endcase
		end
		op_jal: begin 
			ctrl.brtype = 1;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 4;
			ctrl.aluop = alu_add;
			ctrl.load_regfile = 1;
			ctrl.wbmux_sel = 0;	//pc + 4
		end 
		op_jalr: begin
			ctrl.brtype = 2;
			ctrl.alumux1_sel = 0;
			ctrl.alumux2_sel = 0;
			ctrl.aluop = alu_add;
			ctrl.load_regfile = 1;
			ctrl.wbmux_sel = 0;	//pc + 4
		end
	default: begin
		ctrl = 0;   /* Unknown opcode, set control word to zero */
	end
endcase

end
endmodule : control_rom