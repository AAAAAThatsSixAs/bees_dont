module arbiter_control
(
	 input clk,
	 input logic dcache_read,
	 input logic dcache_write,
	 input logic icache_read,
	 input logic mem_resp,
    output logic mux_sel
);

enum int unsigned {
    /* List of states */
	idle,
	service_dcache,
	service_icache
} state, next_state;


always_comb
begin : state_actions

	mux_sel = 1;
	
	case(state)
		idle: mux_sel = 1;
		service_dcache: mux_sel = 1;
		service_icache: mux_sel = 0;
		default: $display("No_state");
	endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	next_state = state;
	case(state)
		idle: begin
			if ((dcache_read || dcache_write ) && !mem_resp) next_state = service_dcache;
			else if ((icache_read && !(dcache_read || dcache_write )) && !mem_resp) next_state = service_icache;
		end
		service_icache: if (mem_resp) next_state = idle;
		service_dcache: if (mem_resp) next_state = idle;
		default: next_state = idle;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
end

endmodule : arbiter_control
