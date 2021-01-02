module EX(
    input wire rst,
    input wire [`RAMAddrLen - 1 : 0] PC,

    // Inst
    input wire [`OpTypeLen - 1 : 0] optype,
    input wire [`OpLen - 1 : 0] opname,
    input wire [`RegAddrLen - 1 : 0] rd_addr,
    input wire [`RegLen - 1 : 0] imm,

    // Data
    input wire [`RegLen - 1 : 0] rs1_data,
    input wire [`RegLen - 1 : 0] rs2_data,

    // ALU Output
    output reg [`RegAddrLen - 1 : 0] rd_addr_o,
    output reg [`RegLen - 1 : 0] rd_data,

    output reg [`RegLen - 1 : 0] s_data,

    output reg load_enable,
    output reg ex_fwd_enable,

    // Inst Passing
    output reg [`OpTypeLen - 1 : 0] optype_o,
    output reg [`OpLen - 1 : 0] opname_o,

    // PC Transfer
    output reg jump_enable,
    output reg [`RAMAddrLen - 1 : 0] JPC
);

    reg branching;

    // calculation
    always @(*) begin
        if (rst == `Enable) begin
            rd_data = `ZeroWord;
            s_data = `ZeroWord;
            JPC = `ZeroWord;
            jump_enable = `Disable;
            load_enable = `Disable;
            ex_fwd_enable = `Disable;
        end
        else begin
            rd_data = `ZeroWord;
            s_data = `ZeroWord;
            JPC = `ZeroWord;
            jump_enable = `Disable;
            load_enable = `Disable;
            ex_fwd_enable = `Enable;
            case (optype)
                `Type_R: begin
                    case (opname)
                        `ADD:  rd_data = rs1_data + rs2_data;
                        `SUB:  rd_data = rs1_data - rs2_data;
                        `SLL:  rd_data = rs1_data << rs2_data[4:0];
                        `SRL:  rd_data = rs1_data >> rs2_data[4:0];
                        `SRA:  rd_data = $signed(rs1_data) >>> rs2_data[4:0];
                        `SLT:  rd_data = {{(`RegLen - 1){1'b0}}, ($signed(rs1_data) < $signed(rs2_data))};
                        `SLTU: rd_data = {{(`RegLen - 1){1'b0}}, (rs1_data < rs2_data)};
                        `XOR:  rd_data = rs1_data ^ rs2_data;
                        `OR:   rd_data = rs1_data | rs2_data;
                        `AND:  rd_data = rs1_data & rs2_data;
                        default: rd_data = `ZeroWord;
                    endcase
                end
                `Type_I: begin
                    case (opname)
                        `ADDI: rd_data = rs1_data + imm;
                        `SLTI: rd_data = {{(`RegLen - 1){1'b0}}, ($signed(rs1_data) < $signed(imm))};
                        `SLTIU:rd_data = {{(`RegLen - 1){1'b0}}, (rs1_data < imm)};
                        `XORI: rd_data = rs1_data ^ imm;
                        `ORI:  rd_data = rs1_data | imm;
                        `ANDI: rd_data = rs1_data & imm;
                        `SLLI: rd_data = rs1_data << imm[4:0];
                        `SRLI: rd_data = rs1_data >> imm[4:0];
                        `SRAI: rd_data = $signed(rs1_data) >>> imm[4:0];
                        default: rd_data = `ZeroWord;
                    endcase
                end
                `Type_IL:begin
                    load_enable = `Enable;
                    ex_fwd_enable = `Disable;
                    rd_data = rs1_data + imm;
                end
                `Type_IJ:begin
                    if (rd_addr != `ZeroRegAddr) rd_data = PC + 4;
                    else rd_data = `ZeroWord;

                    jump_enable = `Enable;
                    JPC = rs1_data + imm;
                    JPC[0] = 1'b0;
                end
                `Type_S: begin
                    ex_fwd_enable = `Disable;
                    rd_data = rs1_data + imm;
                    s_data = rs2_data;
                end
                `Type_SB:begin
                    ex_fwd_enable = `Disable;
                    case (opname)
                        `BEQ: branching = (rs1_data == rs2_data);
                        `BNE: branching = (rs1_data != rs2_data);
                        `BLT: branching = ($signed(rs1_data) <  $signed(rs2_data));
                        `BGE: branching = ($signed(rs1_data) >= $signed(rs2_data));
                        `BLTU:branching = (rs1_data <  rs2_data);
                        `BGEU:branching = (rs1_data >= rs2_data);
                        default: branching = 1'b0;
                    endcase
                    if (branching) begin
                        jump_enable = `Enable;
                        JPC = PC + imm;
                    end
                end
                `Type_U: begin
                    if (opname == `LUI) rd_data = imm;
                    else rd_data = PC + imm; // AUIPC
                end
                `Type_UJ:begin
                    if (rd_addr != `ZeroRegAddr) rd_data = PC + 4;
                    else rd_data = `ZeroWord;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst == `Enable) begin
            optype_o = `Type_I;
            opname_o = `ADDI;
            rd_addr_o = `ZeroRegAddr;
        end
        else begin
            optype_o = optype;
            opname_o = opname;
            rd_addr_o = rd_addr;
        end
    end

endmodule