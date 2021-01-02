module ID (
    input wire rst,
    input wire [`RAMAddrLen - 1 : 0] PC,
    input wire [`InstLen - 1 : 0] inst,

    // Hazard
    input wire load_enable,
    input wire [`RegAddrLen - 1 : 0] ld_addr,
    // forwarding
    input wire ex_fwd_enable,
    input wire [`RegAddrLen - 1 : 0] ex_fwd_rd_addr,
    input wire [`RegLen - 1 : 0] ex_fwd_rd_data,
    input wire mem_fwd_enable,
    input wire [`RegAddrLen - 1 : 0] mem_fwd_rd_addr,
    input wire [`RegLen - 1 : 0] mem_fwd_rd_data,

    // Register
    input wire [`RegLen - 1 : 0] reg_access1_data,
    input wire [`RegLen - 1 : 0] reg_access2_data,
    output reg reg_access1_read_enable,
    output reg [`RegAddrLen - 1 : 0] rs1_addr,
    output reg reg_access2_read_enable,
    output reg [`RegAddrLen - 1 : 0] rs2_addr,

    // Inst
    output reg [`OpTypeLen - 1 : 0] optype,
    output reg [`OpLen - 1 : 0] opname,
    output reg [`RegAddrLen - 1 : 0] rd_addr,
    output reg [`RegLen - 1 : 0] imm,

    // Data
    output reg [`RegLen - 1 : 0] rs1_data,
    output reg [`RegLen - 1 : 0] rs2_data,

    output reg stall_request,
    
    // PC Transfer
    output reg [`RAMAddrLen - 1 : 0] NPC,
    output reg jump_enable,
    output reg [`RAMAddrLen - 1 : 0] JPC
);

    wire [`OpCodeLen - 1 : 0] opcode = inst[`OpCodeLen - 1 : 0];

    // Decode
    always @(*) begin
        // initialize
        reg_access1_read_enable = `Disable;
        reg_access2_read_enable = `Disable;
        rs1_addr = `ZeroRegAddr;
        rs2_addr = `ZeroRegAddr;

        rd_addr = `ZeroRegAddr;
        imm = `ZeroWord;

        NPC = PC;
        jump_enable = `Disable;
        JPC = `ZeroWord;

        case (opcode)
            7'd51: begin
                optype = `Type_R;
                opname = { inst[30], inst[14:12] };

                reg_access1_read_enable = `Enable;
                rs1_addr = inst[19:15];
                reg_access2_read_enable = `Enable;
                rs2_addr = inst[24:20];
                rd_addr = inst[11:7];
            end
            7'd19: begin
                optype = `Type_I;
                opname = { (inst[14:12]==3'b101 ? inst[30] : 1'b0), inst[14:12] };

                reg_access1_read_enable = `Enable;
                rs1_addr = inst[19:15];
                rd_addr = inst[11:7];

                if (opname==`SLLI || opname==`SRLI || opname==`SRAI)
                    imm = { {27{1'b0}}, inst[24:20] };
                else
                    imm = { {20{inst[31]}}, inst[31:20] };
            end
            7'd3: begin
                optype = `Type_IL;
                opname = { 1'b0, inst[14:12] };

                reg_access1_read_enable = `Enable;
                rs1_addr = inst[19:15];
                rd_addr = inst[11:7];

                imm = { {20{inst[31]}}, inst[31:20] };
            end
            7'd103: begin
                optype = `Type_IJ;
                opname = `JALR;

                reg_access1_read_enable = `Enable;
                rs1_addr = inst[19:15];
                rd_addr = inst[11:7];

                imm = { {20{inst[31]}}, inst[31:20] };
            end
            7'd35: begin
                optype = `Type_S;
                opname = { 1'b0, inst[14:12] };

                reg_access1_read_enable = `Enable;
                rs1_addr = inst[19:15];
                reg_access2_read_enable = `Enable;
                rs2_addr = inst[24:20];

                imm = { {20{inst[31]}}, inst[31:25], inst[11:7] };
            end
            7'd99: begin
                optype = `Type_SB;
                opname = { 1'b0, inst[14:12] };

                reg_access1_read_enable = `Enable;
                rs1_addr = inst[19:15];
                reg_access2_read_enable = `Enable;
                rs2_addr = inst[24:20];

                imm = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], {1'b0} };
            end
            7'd55, 7'd23: begin
                optype = `Type_U;
                if (opcode == 7'd55) opname = `LUI;
                else opname = `AUIPC;

                rd_addr = inst[11:7];

                imm = { inst[31:12], {12{1'b0}} };
            end
            7'd111: begin
                optype = `Type_UJ;
                opname =`JAL;

                rd_addr = inst[11:7];

                imm = { {11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], {1'b0} };

                jump_enable = `Enable;
                JPC = PC + imm;
            end
            default: begin
                optype = `Type_I;
                opname = `ADDI;
            end
        endcase
    end

    // Data Fetch
    reg stall_req_rs1, stall_req_rs2;
    always @(*) begin
        stall_req_rs1 = `Disable;
        if (rst == `Enable)
            rs1_data = `ZeroWord;
        else if (reg_access1_read_enable==`Disable || rs1_addr==`ZeroRegAddr)
            rs1_data = `ZeroWord;
        else if (load_enable==`Enable && ld_addr==rs1_addr) begin
            rs1_data = `ZeroWord;
            stall_req_rs1 = `Enable;
        end
        else if (ex_fwd_enable==`Enable && ex_fwd_rd_addr==rs1_addr)
            rs1_data = ex_fwd_rd_data;
        else if (mem_fwd_enable==`Enable && mem_fwd_rd_addr==rs1_addr)
            rs1_data = mem_fwd_rd_data;
        else
            rs1_data = reg_access1_data;
    end
    always @(*) begin
        stall_req_rs2 = `Disable;
        if (rst == `Enable)
            rs2_data = `ZeroWord;
        else if (reg_access2_read_enable==`Disable || rs2_addr==`ZeroRegAddr)
            rs2_data = `ZeroWord;
        else if (load_enable==`Enable && ld_addr==rs2_addr) begin
            rs2_data = `ZeroWord;
            stall_req_rs2 = `Enable;
        end
        else if (ex_fwd_enable==`Enable && ex_fwd_rd_addr==rs2_addr)
            rs2_data = ex_fwd_rd_data;
        else if (mem_fwd_enable==`Enable && mem_fwd_rd_addr==rs2_addr)
            rs2_data = mem_fwd_rd_data;
        else
            rs2_data = reg_access2_data;
    end
    always @(*) begin
        stall_request = stall_req_rs1 | stall_req_rs2;
    end

endmodule