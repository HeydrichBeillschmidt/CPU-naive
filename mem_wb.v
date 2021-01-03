module MEM_WB(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [`StallLevelLen - 1 : 0] stall_command,

    // from mem
    input wire mem_rd_enable,
    input wire [`RegAddrLen - 1 : 0] mem_rd_addr,
    input wire [`RegLen - 1 : 0] mem_rd_data,

    // to reg
    output reg wb_rd_enable,
    output reg [`RegAddrLen - 1 : 0] wb_rd_addr,
    output reg [`RegLen - 1 : 0] wb_rd_data
);

    always @ (posedge clk) begin
        if (rst==`Enable) begin
            wb_rd_enable <= `Disable;
            wb_rd_addr <= `ZeroRegAddr;
            wb_rd_data <= `ZeroWord;
        end
        else if (~rdy) begin
        end
        else if (stall_command==`Stall_All) begin
            wb_rd_enable <= `Disable;
            wb_rd_addr <= `ZeroRegAddr;
            wb_rd_data <= `ZeroWord;
        end
        else begin
            wb_rd_enable <= mem_rd_enable;
            wb_rd_addr <= mem_rd_addr;
            wb_rd_data <= mem_rd_data;
        end
    end

endmodule
