`include "defines.v"
module IFF(
    input wire clk,
    input wire rst,
    input wire [`RAMAddrLen - 1 : 0] FPC,

    // MemCtrl
    input wire [`MCtrlStatLen - 1 : 0] inst_access_stat,
    input wire [`RAMAddrLen - 1 : 0] inst_handled_addr,
    input wire [`InstLen - 1 : 0] inst_access_data,
    output reg inst_access_enable,
    output reg [`RAMAddrLen - 1 : 0] inst_access_addr,

    output reg stall_request,

    output reg [`RAMAddrLen - 1 : 0] NPC,
    output reg [`InstLen - 1 : 0] Inst
);

    reg [`ICacheLineSize - 1 : 0] icache [`ICacheLines - 1 : 0];

    always @(*) begin
        inst_access_enable = (!icache[inst_access_addr[`ICache_Index_H:`ICache_Index_L]][`IValid_Bit]
                            || icache[inst_access_addr[`ICache_Index_H:`ICache_Index_L]][`ICache_Tag_T:`RAMAddrLen]
                            != inst_access_addr[`ICache_Tag_H:`ICache_Tag_L])
                            && inst_access_stat!=`IHandled;
    end

    reg cached_FPC;
    always @(*) begin
        cached_FPC= icache[FPC[`ICache_Index_H:`ICache_Index_L]][`IValid_Bit] &&
                    icache[FPC[`ICache_Index_H:`ICache_Index_L]][`ICache_Tag_T:`RAMAddrLen]==
                    FPC[`ICache_Tag_H:`ICache_Tag_L];
    end
    
    integer i;
    always @(posedge clk) begin
        if (rst == `Enable) begin
            for (i = 0; i < `ICacheLines; i = i + 1) begin
                icache[i][`IValid_Bit] <= 1'b0;
            end
            inst_access_addr <= `ZeroWord;
        end
        else begin
            if (inst_access_stat == `IHandled) begin
                icache[inst_handled_addr[`ICache_Index_H:`ICache_Index_L]]
                    <= {{1'b1},inst_handled_addr[`ICache_Tag_H:`ICache_Tag_L],inst_access_data};
                inst_access_addr <= FPC + 4;
            end
            else if (!cached_FPC) begin
                inst_access_addr <= FPC;
            end
        end
    end

    always @(*) begin
        if (rst == `Enable) begin
            Inst = `ZeroWord;
            NPC = `ZeroWord;
            stall_request = `Disable;
        end
        else if (cached_FPC) begin
            Inst = icache[FPC[`ICache_Index_H:`ICache_Index_L]][`RAMAddrLen - 1 : 0];
            NPC = FPC;
            stall_request = `Disable;
        end
        else if (inst_access_stat==`IHandled && FPC==inst_handled_addr) begin
            Inst = inst_access_data;
            NPC = FPC;
            stall_request = `Disable;
        end
        else begin
            Inst = `ZeroWord;
            NPC = `ZeroWord;
            stall_request = `Enable;
        end
    end

endmodule