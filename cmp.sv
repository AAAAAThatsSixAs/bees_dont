import rv32i_types::*;

module cmp
(
    input rv32i_word a,
    input rv32i_word b,
	 input branch_funct3_t cmpop,
    output logic result
);

always_comb
begin
    case (cmpop)
		 beq:  result = (a == b);
		 bne:  result = (a != b);
		 blt:  result = ($signed(a) < $signed(b));
		 bge:  result = ($signed(a) >= $signed(b));
		 bltu: result = ($unsigned(a) < $unsigned(b));
		 bgeu: result = ($unsigned(a) >= $unsigned(b));
		 default: result = 0;
    endcase
end

endmodule : cmp
