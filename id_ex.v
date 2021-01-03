module ID_EX(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [`JumpInfoLen - 1 : 0] jp,
    input wire [`StallLevelLen - 1 : 0] stall_command,

    // inst
    input wire [`OpTypeLen - 1 : 0] optype,
    input wire [`OpLen - 1 : 0] opname,
    input wire [`RegAddrLen - 1 : 0] rd_addr,
    input wire [`RegLen - 1 : 0] imm,

    // data
    input wire [`RegLen - 1 : 0] rs1_data,
    input wire [`RegLen - 1 : 0] rs2_data,

    input wire [`RAMAddrLen - 1 : 0] PC,
    output reg [`RAMAddrLen - 1 : 0] NPC,

    // to ex
    output reg [`OpTypeLen - 1 : 0] optype_o,
    output reg [`OpLen - 1 : 0] opname_o,
    output reg [`RegAddrLen - 1 : 0] rd_addr_o,
    output reg [`RegLen - 1 : 0] rs1_data_o,
    output reg [`RegLen - 1 : 0] rs2_data_o,
    output reg [`RegLen - 1 : 0] imm_o
);

    always @(posedge clk) begin
        if (rst==`Enable) begin
            rs1_data_o <= `ZeroWord;
            rs2_data_o <= `ZeroWord;
            rd_addr_o <= `ZeroRegAddr;
            imm_o <= `ZeroWord;
            NPC <= `ZeroWord;
            optype_o <= `Type_I;
            opname_o <= `ADDI;
        end
        else if (~rdy) begin
        end
        else if (stall_command==`Stall_All) begin
            optype_o <= optype_o;
            opname_o <= opname_o;
            rd_addr_o <= rd_addr_o;
            imm_o <= imm_o;
            NPC <= NPC;
            rs1_data_o <= rs1_data_o;
            rs2_data_o <= rs2_data_o;
        end
        else if (jp[`Jump_EX]==`Enable || stall_command==`Stall_Issue) begin
            rs1_data_o <= `ZeroWord;
            rs2_data_o <= `ZeroWord;
            rd_addr_o <= `ZeroRegAddr;
            imm_o <= `ZeroWord;
            NPC <= `ZeroWord;
            optype_o <= `Type_I;
            opname_o <= `ADDI;
        end
        else if (jp[`Jump_ID]==`Enable || stall_command==`Stall_Null || stall_command==`Stall_Decode) begin
            optype_o <= optype;
            opname_o <= opname;
            rd_addr_o <= rd_addr;
            imm_o <= imm;
            NPC <= PC;
            rs1_data_o <= rs1_data;
            rs2_data_o <= rs2_data;
        end
        else begin
            optype_o <= optype_o;
            opname_o <= opname_o;
            rd_addr_o <= rd_addr_o;
            imm_o <= imm_o;
            NPC <= NPC;
            rs1_data_o <= rs1_data_o;
            rs2_data_o <= rs2_data_o;
        end
    end

endmodule
