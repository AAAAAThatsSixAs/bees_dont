module l2_cache_control (
	input clk,
	input logic hit,
	input logic hit0,
	input logic hit1,
	input logic hit2,
	input logic hit3,
	input logic [1:0] lru_out,
	output logic [3:0] dirty_in,
	output logic dirty_read,
	output logic [3:0] dirty_load,
	output logic valid_read,
	output logic [3:0] valid_load,
	output logic line_read,
	output logic lru_read,
	output logic pmem_addr_muxsel,
	output logic load_filldata,
	output logic tag_read,
	output logic [3:0] tag_load,
	output logic lru_load,
	output logic compare_read,
	input logic is_dirty,
	output logic mbe_sel,
	output logic [3:0] mbe_way_sel,
	input logic pmem_resp,
	output logic pmem_read,
	output logic pmem_write,
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp
);

enum int unsigned {
    /* List of states */
    idle,
	 check_hit,
	 writeback,
	 allocate
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
	 dirty_in = 4'b0000;
    tag_read = 1'b0;
	 dirty_read = 1'b0;
	 valid_read = 1'b0;
	 line_read = 1'b0;
	 lru_read = 0;
	 tag_load = 4'b0;
	 dirty_load = 4'b0;
	 valid_load = 4'b0;
	 lru_load = 0;
	 compare_read = 0;
	 
	 mem_resp = 0;
	 pmem_addr_muxsel = 0;
	 pmem_read = 0;
	 pmem_write = 0;
	 
	 load_filldata = pmem_resp;
	 
	 mbe_sel = 0;
	 mbe_way_sel = 4'b0;
    
	 case(state)
        idle: begin
				tag_read = (mem_read || mem_write);
				dirty_read = (mem_read || mem_write);
				valid_read = (mem_read || mem_write);
				line_read = (mem_read || mem_write);
				compare_read = (mem_read || mem_write);
				lru_read = (mem_read || mem_write);
				lru_load = hit;
				if (mem_write && hit) 
					begin
					dirty_in = 4'b1111;
					mbe_sel = 0;
					if (hit0) begin
						mbe_way_sel[0] = 1;
						dirty_load[0] = 1;
					end
					else if (hit1) begin
						mbe_way_sel[1] = 1;
						dirty_load[1] = 1;
					end
					else if (hit2) begin
						mbe_way_sel[2] = 1;
						dirty_load[2] = 1;
					end
					else begin
						mbe_way_sel[3] = 1;
						dirty_load[3] = 1;
					end
					end
				mem_resp = hit;
	
        end
		  writeback: begin
				pmem_addr_muxsel = 1;
				pmem_write = 1;

        end
		  allocate: begin
				//set tag, dirty, valid
				pmem_read = 1;
				pmem_addr_muxsel = 0;
				dirty_in = 4'b0000;
				lru_read = 1;
				
				if (pmem_resp)
					begin
					mbe_sel = 1;
					mbe_way_sel[lru_out] = 1;
					valid_load[lru_out] = 1'b1;
					dirty_load[lru_out] = 1'b1;
					tag_load[lru_out] = 1'b1;
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
				case(mem_read || mem_write)
					0: next_state = idle;
					1:	case(hit)	
						0: case(is_dirty)
								0: next_state = allocate;
								1: next_state = writeback;
							endcase
						1:	next_state = idle;
					   endcase
				 endcase
        writeback: if (pmem_resp) 
							next_state = allocate;
						else 
							next_state = writeback;
        allocate: if (pmem_resp) 
							next_state = idle;
						else
							next_state = allocate;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : l2_cache_control
