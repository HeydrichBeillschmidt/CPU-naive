// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	
	  input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	  output wire [31:0]			    dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    wire rdy_sys = rdy_in & ~io_buffer_full;

    wire [`StallLevelLen - 1 : 0] stall_cmd_bus;
    wire stall_req_if;
    wire stall_req_id;
    wire stall_req_mem;

    wire [`JumpInfoLen - 1 : 0] jp_info; 
    wire [`RAMAddrLen - 1 : 0] JPC_id;
    wire [`RAMAddrLen - 1 : 0] JPC_ex;
    wire [`RAMAddrLen - 1 : 0] JPC_mux;

    wire [`RAMAddrLen - 1 : 0] PC_pcreg_if;
    wire [`RAMAddrLen - 1 : 0] PC_if_id_i;
    wire [`RAMAddrLen - 1 : 0] PC_if_id_o;
    wire [`RAMAddrLen - 1 : 0] PC_id_ex_i;
    wire [`RAMAddrLen - 1 : 0] PC_id_ex_o;

    assign dbgreg_dout = PC_pcreg_if;

    wire [`RegLen - 1 : 0] memctrl_access_data;
    wire [`MCtrlStatLen - 1 : 0] memctrl_access_stat;
    wire [`RAMAddrLen - 1 : 0] memctrl_handled_addr;
    wire if_memctrl_access_enable;
    wire [`RAMAddrLen - 1 : 0] if_memctrl_access_addr;
    wire mem_memctrl_access_enable;
    wire mem_memctrl_access_sel;
    wire [`MSelLen - 1 : 0] mem_memctrl_access_type;
    wire [`RAMAddrLen - 1 : 0] mem_memctrl_access_addr;
    wire [`RegLen - 1 : 0] mem_memctrl_access_dout;

    wire [`InstLen - 1 : 0] raw_inst_i;
    wire [`InstLen - 1 : 0] raw_inst_o;

    wire [`RegLen - 1 : 0] id_reg_data1;
    wire [`RegLen - 1 : 0] id_reg_data2;
    wire id_reg_read1_enable;
    wire id_reg_read2_enable;
    wire [`RegAddrLen - 1 : 0] id_reg_access1_addr;
    wire [`RegAddrLen - 1 : 0] id_reg_access2_addr;

    wire [`OpTypeLen - 1 : 0] id_ex_optype_i;
    wire [`OpTypeLen - 1 : 0] id_ex_optype_o;
    wire [`OpLen - 1 : 0] id_ex_opname_i;
    wire [`OpLen - 1 : 0] id_ex_opname_o;

    wire [`OpTypeLen - 1 : 0] ex_mem_optype_i;
    wire [`OpTypeLen - 1 : 0] ex_mem_optype_o;
    wire [`OpLen - 1 : 0] ex_mem_opname_i;
    wire [`OpLen - 1 : 0] ex_mem_opname_o;

    wire [`RegAddrLen - 1 : 0] id_ex_rd_addr_i;
    wire [`RegLen - 1 : 0] id_ex_imm_i;
    wire [`RegAddrLen - 1 : 0] id_ex_rd_addr_o;
    wire [`RegLen - 1 : 0] id_ex_imm_o;

    wire [`RegLen - 1 : 0] id_ex_rs1_v_i;
    wire [`RegLen - 1 : 0] id_ex_rs2_v_i;
    wire [`RegLen - 1 : 0] id_ex_rs1_v_o;
    wire [`RegLen - 1 : 0] id_ex_rs2_v_o;
    
    wire [`RegAddrLen - 1 : 0] ex_mem_rd_addr_i;
    wire [`RegLen - 1 : 0] ex_mem_rd_v_i;
    wire [`RegLen - 1 : 0] ex_mem_s_v_i;
    wire [`RegAddrLen - 1 : 0] ex_mem_rd_addr_o;
    wire [`RegLen - 1 : 0] ex_mem_rd_v_o;
    wire [`RegLen - 1 : 0] ex_mem_s_v_o;

    wire ex_id_ld_enable;
    wire ex_id_fwd_enable;

    wire mem_wb_rd_enable_i;
    wire [`RegAddrLen - 1 : 0] mem_wb_rd_addr_i;
    wire [`RegLen - 1 : 0] mem_wb_rd_v_i;
    wire mem_wb_rd_enable_o;
    wire [`RegAddrLen - 1 : 0] mem_wb_rd_addr_o;
    wire [`RegLen - 1 : 0] mem_wb_rd_v_o;

    PC_REG pc_reg(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                  .stall_command(stall_cmd_bus),
                  .jp(jp_info), .JPC(JPC_mux),
                  .PC(PC_pcreg_if));

    IFF iff(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
            .FPC(PC_pcreg_if),
            .inst_access_stat(memctrl_access_stat),
            .inst_access_data(memctrl_access_data), .inst_handled_addr(memctrl_handled_addr),
            .inst_access_enable(if_memctrl_access_enable), .inst_access_addr(if_memctrl_access_addr),
            .stall_request(stall_req_if),
            .NPC(PC_if_id_i),
            .Inst(raw_inst_i));
    
    IF_ID if_id(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                .jp(jp_info),
                .stall_command(stall_cmd_bus),
                .if_pc(PC_if_id_i), .if_inst(raw_inst_i),
                .id_pc(PC_if_id_o), .id_inst(raw_inst_o));

    ID id(.rst(rst_in),
          .PC(PC_if_id_o), .inst(raw_inst_o),
          .load_enable(ex_id_ld_enable), .ld_addr(ex_mem_rd_addr_i),
          .ex_fwd_enable(ex_id_fwd_enable), .ex_fwd_rd_addr(ex_mem_rd_addr_i), .ex_fwd_rd_data(ex_mem_rd_v_i),
          .mem_fwd_enable(mem_wb_rd_enable_i), .mem_fwd_rd_addr(mem_wb_rd_addr_i), .mem_fwd_rd_data(mem_wb_rd_v_i),
          .reg_access1_data(id_reg_data1), .reg_access2_data(id_reg_data2),
          .reg_access1_read_enable(id_reg_read1_enable), .rs1_addr(id_reg_access1_addr),
          .reg_access2_read_enable(id_reg_read2_enable), .rs2_addr(id_reg_access2_addr),
          .optype(id_ex_optype_i), .opname(id_ex_opname_i),
          .rd_addr(id_ex_rd_addr_i), .imm(id_ex_imm_i),
          .rs1_data(id_ex_rs1_v_i), .rs2_data(id_ex_rs2_v_i),
          .stall_request(stall_req_id),
          .NPC(PC_id_ex_i),
          .jump_enable(jp_info[`Jump_ID]), .JPC(JPC_id));

    ID_EX id_ex(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                .jp(jp_info),
                .stall_command(stall_cmd_bus),
                .optype(id_ex_optype_i), .opname(id_ex_opname_i),
                .rd_addr(id_ex_rd_addr_i), .imm(id_ex_imm_i),
                .rs1_data(id_ex_rs1_v_i), .rs2_data(id_ex_rs2_v_i),
                .PC(PC_id_ex_i), .NPC(PC_id_ex_o),
                .optype_o(id_ex_optype_o), .opname_o(id_ex_opname_o),
                .rd_addr_o(id_ex_rd_addr_o), .imm_o(id_ex_imm_o),
                .rs1_data_o(id_ex_rs1_v_o), .rs2_data_o(id_ex_rs2_v_o));

    EX ex(.rst(rst_in),
          .PC(PC_id_ex_o),
          .optype(id_ex_optype_o), .opname(id_ex_opname_o),
          .rd_addr(id_ex_rd_addr_o), .imm(id_ex_imm_o),
          .rs1_data(id_ex_rs1_v_o), .rs2_data(id_ex_rs2_v_o),
          .rd_addr_o(ex_mem_rd_addr_i), .rd_data(ex_mem_rd_v_i),
          .s_data(ex_mem_s_v_i),
          .load_enable(ex_id_ld_enable), .ex_fwd_enable(ex_id_fwd_enable),
          .optype_o(ex_mem_optype_i), .opname_o(ex_mem_opname_i),
          .jump_enable(jp_info[`Jump_EX]), .JPC(JPC_ex));

    EX_MEM ex_mem(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                  .stall_command(stall_cmd_bus),
                  .optype(ex_mem_optype_i), .opname(ex_mem_opname_i),
                  .ex_rd_addr(ex_mem_rd_addr_i), .ex_rd_data(ex_mem_rd_v_i), .ex_s_data(ex_mem_s_v_i),
                  .mem_rd_addr(ex_mem_rd_addr_o), .mem_rd_data(ex_mem_rd_v_o), .mem_s_data(ex_mem_s_v_o),
                  .optype_o(ex_mem_optype_o), .opname_o(ex_mem_opname_o));

    MEM mem(.rst(rst_in),
            .optype(ex_mem_optype_o), .opname(ex_mem_opname_o),
            .rd_addr(ex_mem_rd_addr_o), .rd_data(ex_mem_rd_v_o), .s_data(ex_mem_s_v_o),
            .mem_access_stat(memctrl_access_stat), .mem_access_din(memctrl_access_data),
            .mem_access_enable(mem_memctrl_access_enable), .mem_access_addr(mem_memctrl_access_addr),
            .mem_access_type(mem_memctrl_access_type), .mem_access_sel(mem_memctrl_access_sel),
            .mem_access_dout(mem_memctrl_access_dout),
            .stall_request(stall_req_mem),
            .wb_enable(mem_wb_rd_enable_i), .wb_addr(mem_wb_rd_addr_i), .wb_data(mem_wb_rd_v_i));

    MEM_WB mem_wb(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                  .stall_command(stall_cmd_bus),
                  .mem_rd_enable(mem_wb_rd_enable_i), .mem_rd_addr(mem_wb_rd_addr_i), .mem_rd_data(mem_wb_rd_v_i),
                  .wb_rd_enable(mem_wb_rd_enable_o), .wb_rd_addr(mem_wb_rd_addr_o), .wb_rd_data(mem_wb_rd_v_o));

    REGFILE regfile(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                    .read1_enable(id_reg_read1_enable), .read1_addr(id_reg_access1_addr),
                    .read2_enable(id_reg_read2_enable), .read2_addr(id_reg_access2_addr),
                    .write_enable(mem_wb_rd_enable_o), .write_addr(mem_wb_rd_addr_o), .write_data(mem_wb_rd_v_o),
                    .read1_data(id_reg_data1), .read2_data(id_reg_data2));

    MEM_CTRL mem_ctrl(.clk(clk_in), .rst(rst_in), .rdy(rdy_sys),
                      .ctrl_request_enable_if(if_memctrl_access_enable), .ctrl_request_addr_if(if_memctrl_access_addr),
                      .ctrl_request_enable_mem(mem_memctrl_access_enable), .ctrl_request_addr_mem(mem_memctrl_access_addr),
                      .ctrl_func_sel(mem_memctrl_access_sel), .ctrl_rw_type(mem_memctrl_access_type),
                      .ctrl_request_dout(mem_memctrl_access_dout),
                      .ram_access_data(mem_din),
                      .ram_access_addr(mem_a), .ram_access_sel(mem_wr),
                      .ram_access_dout(mem_dout),
                      .ctrl_request_data(memctrl_access_data), .mem_ctrl_handled_addr(memctrl_handled_addr),
                      .mem_ctrl_stat(memctrl_access_stat));

    MUX_JP mux_jp(.jp_info(jp_info),
                  .id_JPC(JPC_id), .ex_JPC(JPC_ex),
                  .JPC(JPC_mux));

    STALL_BUS stall_bus(.req_if(stall_req_if), .req_id(stall_req_id), .req_mem(stall_req_mem), 
                        .stall_level(stall_cmd_bus));

endmodule
