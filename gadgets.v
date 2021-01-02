`include "defines.v"
module MUX_JP(
    input wire [`JumpInfoLen - 1 : 0] jp_info,
    input wire [`RAMAddrLen - 1 : 0] id_JPC,
    input wire [`RAMAddrLen - 1 : 0] ex_JPC,

    output reg [`RAMAddrLen - 1 : 0] JPC
);

    always @(*) begin
        JPC = jp_info[`Jump_EX] ? ex_JPC
                                : (jp_info[`Jump_ID] ? id_JPC : `ZeroWord);
    end

endmodule