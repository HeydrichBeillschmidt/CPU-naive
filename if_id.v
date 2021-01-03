module IF_ID(
    input wire clk, 
    input wire rst,
    input wire rdy,

    input wire [`JumpInfoLen - 1 : 0] jp,
    input wire [`StallLevelLen - 1 : 0] stall_command,

    input wire [`RAMAddrLen - 1 : 0] if_pc,
    input wire [`InstLen - 1 : 0] if_inst,
    output reg [`RAMAddrLen - 1 : 0] id_pc,
    output reg [`InstLen - 1 : 0] id_inst
);
    
    always @ (posedge clk) begin
        if (rst == `Enable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else if (~rdy) begin
        end
        else if (jp[`Jump_EX]==`Enable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else if (stall_command==`Stall_All || stall_command==`Stall_Issue) begin
            id_pc <= id_pc;
            id_inst <= id_inst;
        end
        else if (jp[`Jump_ID]==`Enable || stall_command == `Stall_Decode) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else if (stall_command == `Stall_Null) begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
        else begin
            id_pc <= id_pc;
            id_inst <= id_inst;
        end
    end

endmodule
