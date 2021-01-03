module EX_MEM(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [`StallLevelLen - 1 : 0] stall_command,

    // Inst
    input wire [`OpTypeLen - 1 : 0] optype,
    input wire [`OpLen - 1 : 0] opname,

    // from ex
    input wire [`RegAddrLen - 1 : 0] ex_rd_addr,
    input wire [`RegLen - 1 : 0] ex_rd_data,
    input wire [`RegLen - 1 : 0] ex_s_data,
    
    // to mem
    output reg [`RegAddrLen - 1 : 0] mem_rd_addr,
    output reg [`RegLen - 1 : 0] mem_rd_data,
    output reg [`RegLen - 1 : 0] mem_s_data,

    output reg [`OpTypeLen - 1 : 0] optype_o,
    output reg [`OpLen - 1 : 0] opname_o
);

always @(posedge clk) begin
    if (rst == `Enable) begin
        mem_rd_addr <= `ZeroRegAddr;
        mem_rd_data <= `ZeroWord;
        mem_s_data <= `ZeroWord;
        optype_o <= `Type_SB;
        opname_o <= `BEQ;
    end
    else if (~rdy) begin
    end
    else if (stall_command != `Stall_All) begin
        mem_rd_addr <= ex_rd_addr;
        mem_rd_data <= ex_rd_data;
        mem_s_data <= ex_s_data;
        optype_o <= optype;
        opname_o <= opname;
    end
    else begin
        mem_rd_addr <= mem_rd_addr;
        mem_rd_data <= mem_rd_data;
        mem_s_data <= mem_s_data;
        optype_o <= optype_o;
        opname_o <= opname_o;
    end
end

endmodule
