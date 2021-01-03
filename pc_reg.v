`include "defines.v"
module PC_REG(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire [`StallLevelLen - 1 : 0] stall_command,
    input wire [`JumpInfoLen - 1 : 0] jp,
    input wire [`RAMAddrLen - 1 : 0] JPC,
    output reg [`RAMAddrLen - 1 : 0] PC
);

    always @(posedge clk) begin
        if (rst == `Enable)
            PC <= `ZeroWord;
        else if (~rdy) begin
        end
        else if (|jp)
            PC <= JPC;
        else if (stall_command == `Stall_Null) begin
            PC <= PC + 4'h4;
        end
        else begin
            PC <= PC;
        end
    end

endmodule
