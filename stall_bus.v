module STALL_BUS(
    input wire req_if,
    input wire req_id,
    input wire req_mem,

    output reg [`StallLevelLen - 1 : 0] stall_level
);

    always @(*) begin
        if (req_mem) stall_level = `Stall_All;
        else if (req_id) stall_level = `Stall_Issue;
        else if (req_if) stall_level = `Stall_Decode;
        else stall_level = `Stall_Null;
    end

endmodule
