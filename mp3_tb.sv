module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;
logic pmem_resp;
logic pmem_read;
logic pmem_write;
logic [31:0] pmem_address;
logic [255:0] pmem_wdata;
logic [255:0] pmem_rdata;

logic [15:0] errcode;

initial
begin
    clk = 0;
end

/* Clock generator */
always #5 clk = ~clk;

mp3 dut
(
    .clk,
	 .pmem_read,
	 .pmem_write,
	 .pmem_address,
	 .pmem_wdata,
	 .pmem_resp,
	 .pmem_rdata
);

/* Physical Memory */
physical_memory memory
(
    .clk,
    .read(pmem_read),
    .write(pmem_write),
    .address(pmem_address),
    .wdata(pmem_wdata),
    .resp(pmem_resp),
    .rdata(pmem_rdata),
	 .error(errcode[0])
);
/*
shadow_memory sm (
    .clk,
    .valid(dut.cpu.load_pc),
    .rmask(dut.cpu.control.rmask),
    .wmask(dut.cpu.control.wmask),
    .addr(dut.mem_address),
    .rdata(dut.cpu.datapath.mdrreg_out),
    .wdata(dut.cpu.datapath.mem_wdata),
    .pc_rdata(dut.cpu.datapath.pc_out),
    .insn(dut.cpu.datapath.IR.data),
    .error(errcode[1])
);
*/

/*
riscv_formal_monitor_rv32i monitor
(
  .clock(clk),
  .reset(1'b0),
  .rvfi_valid(dut.load_pc),
  .rvfi_order(order),
  .rvfi_insn(dut.datapath.IR.data),
  .rvfi_trap(dut.control.trap),
  .rvfi_halt(halt),
  .rvfi_intr(1'b0),
  .rvfi_rs1_addr(dut.control.rs1_addr),
  .rvfi_rs2_addr(dut.control.rs2_addr),
  .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.datapath.rs1_out : 0),
  .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.datapath.rs2_out : 0),
  .rvfi_rd_addr(dut.load_regfile ? dut.datapath.rd : 5'h0),
  .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.datapath.regfilemux_out : 0),
  .rvfi_pc_rdata(dut.datapath.pc_out),
  .rvfi_pc_wdata(dut.datapath.pcmux_out),
  .rvfi_mem_addr(mem_address),
  .rvfi_mem_rmask(dut.control.rmask),
  .rvfi_mem_wmask(dut.control.wmask),
  .rvfi_mem_rdata(dut.datapath.mdrreg_out),
  .rvfi_mem_wdata(dut.datapath.mem_wdata),
  .errcode(errcode)
);
*/
endmodule : mp3_tb