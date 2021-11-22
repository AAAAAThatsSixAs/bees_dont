module pipeline_cache_control (
	input clk,
	input logic hit,
	input logic hit0,
	input logic hit1,
	input logic lru_out,
	output logic [1:0] dirty_in,
	output logic [1:0] dirty_read,
	output logic [1:0] dirty_load,
	output logic [1:0] valid_read,
	output logic [1:0] valid_load,
	output logic [1:0] line_read,
	output logic lru_read,
	output logic pmem_addr_muxsel,
	output logic load_filldata,
	output logic [1:0] tag_read,
	output logic [1:0] tag_load,
	output logic lru_load,
	output logic compare_read,
	output logic cache_stall,
	input logic is_dirty,
	output logic use_resp_addr,
	output logic mbe_sel,
	output logic [1:0] mbe_way_sel,
	input logic pmem_resp,
	output logic pmem_read,
	output logic pmem_write,
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp,
	input logic cpu_stall,
	input logic clear
);

enum int unsigned {
    /* List of states */
    idle,
	 rcheck_hit,
	 rwriteback,
	 rallocate,
	 rverify_hit,
	 wcheck_hit,
	 wwriteback,
	 wallocate,
	 wverify_hit
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
	 dirty_in = 2'b0;
    tag_read = 2'b0;
	 dirty_read = 2'b0;
	 valid_read = 2'b0;
	 line_read = 2'b0;
	 lru_read = 0;
	 tag_load = 0;
	 dirty_load = 2'b0;
	 valid_load = 2'b0;
	 lru_load = 0;
	 compare_read = 0;
	 
	 mem_resp = 0;
	 pmem_addr_muxsel = 0;
	 pmem_read = 0;
	 pmem_write = 0;
	 
	 load_filldata = pmem_resp;
	 
	 mbe_sel = 0;
	 mbe_way_sel = 2'b0;
    cache_stall = 0;
	 use_resp_addr = 0;
	 case(state)
        idle: begin
				tag_read = {2{(mem_read || mem_write)}};
				dirty_read = {2{(mem_read || mem_write)}};
				valid_read = {2{(mem_read || mem_write)}};
				line_read = {2{(mem_read || mem_write)}};
				compare_read = (mem_read || mem_write);
				lru_read = (mem_read || mem_write);
		  end
		  rcheck_hit: begin
				//modify parts of cache line and LRU
				tag_read = 2'b11;
				dirty_read = 2'b11;
				valid_read = 2'b11;
				line_read = 2'b11;
				compare_read = 1'b1;
				lru_read = 1'b1;
				lru_load = hit;
				mem_resp = hit || clear;
				cache_stall = !hit || cpu_stall;
				use_resp_addr = !hit;
        end
		  rwriteback: begin
				pmem_addr_muxsel = 1;
				pmem_write = 1;
				cache_stall = 1;
				use_resp_addr = 1;
        end
		  rallocate: begin
				//set tag, dirty, valid
				pmem_read = 1;
				pmem_addr_muxsel = 0;
				dirty_in = 2'b0;
				cache_stall = 1;
				
				if (pmem_resp)
					begin
					mbe_sel = 1;
					mbe_way_sel[lru_out] = 1;
					valid_load[lru_out] = 1'b1;
					dirty_load[lru_out] = 1'b1;
					tag_load[lru_out] = 1'b1;
					tag_read = 2'b11;
					dirty_read = 2'b11;
					valid_read = 2'b11;
					line_read = 2'b11;
					compare_read = 1'b1;
					lru_read = 1'b1;
					use_resp_addr = 1;
					end
		  end
		  rverify_hit: begin
				tag_read = 2'b11;
				dirty_read = 2'b11;
				valid_read = 2'b11;
				line_read = 2'b11;
				compare_read = 1'b1;
				lru_read = 1'b1;
				lru_load = hit;
				use_resp_addr = cpu_stall;
				mem_resp = hit;
				cache_stall = !hit || cpu_stall;		// || cpu_stall		PROBLEM! we have issues with resp not waiting for the stall to end. this fixes that.. but introduces other problems
		  end
		  wcheck_hit: begin
				//modify parts of cache line and LRU
				tag_read = 2'b11;
				dirty_read = 2'b11;
				valid_read = 2'b11;
				line_read = 2'b11;
				compare_read = 1'b1;
				lru_read = 1'b1;
				lru_load = hit;
				if (hit) 
					begin
					dirty_in = 2'b11;
					mbe_sel = 0;
					if (hit0)
					begin
						mbe_way_sel[0] = 1;
						dirty_load[0] = 1;
					end
					else
					begin
						mbe_way_sel[1] = 1;
						dirty_load[1] = 1;
					end
					end
				mem_resp = hit || clear;
				cache_stall = !hit || cpu_stall;
				use_resp_addr = !hit;
        end
		  wwriteback: begin
				pmem_addr_muxsel = 1;
				pmem_write = 1;
				cache_stall = 1;
				use_resp_addr = 1;
        end		  
		  wallocate: begin
				//set tag, dirty, valid
				pmem_read = 1;
				pmem_addr_muxsel = 0;
				dirty_in = 2'b0;
				cache_stall = 1;
				
				if (pmem_resp)
					begin
					mbe_sel = 1;
					mbe_way_sel[lru_out] = 1;
					valid_load[lru_out] = 1'b1;
					dirty_load[lru_out] = 1'b1;
					tag_load[lru_out] = 1'b1;
					tag_read = 2'b11;
					dirty_read = 2'b11;
					valid_read = 2'b11;
					line_read = 2'b11;
					compare_read = 1'b1;
					lru_read = 1'b1;
					use_resp_addr = 1;
					end
		  end
		  wverify_hit: begin
				tag_read = 2'b11;
				dirty_read = 2'b11;
				valid_read = 2'b11;
				line_read = 2'b11;
				compare_read = 1'b1;
				lru_read = 1'b1;
				lru_load = hit;
				use_resp_addr = cpu_stall;
				mem_resp = hit;
				cache_stall = !hit || cpu_stall;		// || cpu_stall		PROBLEM! we have issues with resp not waiting for the stall to end. this fixes that.. but introduces other problems	
				if (hit) 
					begin
					dirty_in = 2'b11;
					mbe_sel = 0;
					if (hit0)
					begin
						mbe_way_sel[0] = 1;
						dirty_load[0] = 1;
					end
					else
					begin
						mbe_way_sel[1] = 1;
						dirty_load[1] = 1;
					end
					end
		  end
		  default:;
		endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */	  
	 next_state = state;
	 
	 case(state)
		  idle: 
				if (mem_read)
					next_state = rcheck_hit;
				else if (mem_write)
					next_state = wcheck_hit;
		  rcheck_hit: 
				if (clear)
					next_state = idle;
				else if (hit)
					if (cpu_stall)
						next_state = rcheck_hit;
					else if (mem_read)
						next_state = rcheck_hit;
					else if (mem_write)
						next_state = wcheck_hit;
					else
						next_state = idle;
				else
					if (is_dirty)
						next_state = rwriteback;
					else
						next_state = rallocate;
		  rwriteback: 
				if (pmem_resp) 
					next_state = rallocate;
				else 
					next_state = rwriteback;
		  rallocate: 
				if (pmem_resp) 
					next_state = rverify_hit;
				else
					next_state = rallocate;
		  rverify_hit: 
				if (clear)
					next_state = idle;
				else if (cpu_stall)
					next_state = rverify_hit;
				else if (hit)
					if (mem_read) 
						 next_state = rcheck_hit;
					else if (mem_write)
						 next_state = wcheck_hit;
					else
						 next_state = idle;
				else
					next_state = rverify_hit;
		  wcheck_hit: 
				if (clear)
					next_state = idle;
				else if (hit)
					if (cpu_stall)
						next_state = wcheck_hit;
					else if (mem_read)
						next_state = rcheck_hit;
					else if (mem_write)
						next_state = wcheck_hit;
					else
						next_state = idle;
				else
					if (is_dirty)
						next_state = wwriteback;
					else
						next_state = wallocate;
		  wwriteback: 
				if (pmem_resp) 
					next_state = wallocate;
				else 
					next_state = wwriteback;
		  wallocate: 
				if (pmem_resp) 
					next_state = wverify_hit;
				else
					next_state = wallocate;
		  wverify_hit: 
				if (clear)
					next_state = idle;
				else if (cpu_stall)
					next_state = wverify_hit;
				else if (hit)
					if (mem_read) 
						 next_state = rcheck_hit;
					else if (mem_write)
						 next_state = wcheck_hit;
					else
						 next_state = idle;
				else
					next_state = wverify_hit;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : pipeline_cache_control
