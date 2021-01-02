`include "defines.v"
module MEM(
    input wire rst,

    // Inst
    input wire [`OpTypeLen - 1 : 0] optype,
    input wire [`OpLen - 1 : 0] opname,

    // input data
    input wire [`RegAddrLen - 1 : 0] rd_addr,
    input wire [`RegLen - 1 : 0] rd_data,
    input wire [`RegLen - 1 : 0] s_data,

    // MemCtrl
    input wire [`MCtrlStatLen - 1 : 0] mem_access_stat,
    input wire [`RegLen - 1 : 0] mem_access_din,
    output reg mem_access_enable,
    output reg mem_access_sel,
    output reg [`MSelLen - 1 : 0] mem_access_type,
    output reg [`RAMAddrLen - 1 : 0] mem_access_addr,
    output reg [`RegLen - 1 : 0] mem_access_dout,

    output reg stall_request,

    // output data
    output reg wb_enable,
    output reg [`RegAddrLen - 1 : 0] wb_addr,
    output reg [`RegLen - 1 : 0] wb_data
);

    reg [`RegLen - 1 : 0] mem_access_data;

    always @(*) begin
        if (rst == `Enable) begin
            wb_enable = `Disable;
            wb_addr = `ZeroRegAddr;
            wb_data = `ZeroWord;
            stall_request = `Disable;
            mem_access_enable = `Disable;
            mem_access_sel = `Read;
            mem_access_type = `Word;
            mem_access_addr = `ZeroWord;
            mem_access_dout = `ZeroWord;
        end
        else begin
            case (optype)
                `Type_IL:begin
                    mem_access_sel = `Read;
                    mem_access_dout = `ZeroWord;
                    if (mem_access_stat == `DHandled) begin
                        mem_access_data = mem_access_din;
                        wb_enable = `Enable;
                        wb_addr = rd_addr;
                        case (opname)
                            `LW:  wb_data = mem_access_data;
                            `LH:  wb_data = {{16{mem_access_data[15]}}, mem_access_data[15:0]};
                            `LB:  wb_data = {{24{mem_access_data[7]}}, mem_access_data[7:0]};
                            `LHU: wb_data = {{16{1'b0}}, mem_access_data[15:0]};
                            `LBU: wb_data = {{24{1'b0}}, mem_access_data[7:0]};
                            default: begin
                                wb_enable = `Disable;
                                wb_data = `ZeroWord;
                            end
                        endcase
                        mem_access_enable = `Disable;
                        mem_access_type = `Word;
                        mem_access_addr = `ZeroWord;
                        stall_request = `Disable;
                    end
                    else begin
                        wb_enable = `Disable;
                        wb_addr = `ZeroRegAddr;
                        wb_data = `ZeroWord;
                        mem_access_enable = `Enable;
                        mem_access_addr = rd_data;
                        stall_request = `Enable;
                        case (opname)
                            `LW:      mem_access_type = `Word;
                            `LH,`LHU: mem_access_type = `Half;
                            `LB,`LBU: mem_access_type = `Byte; 
                            default:  mem_access_type = `Word;
                        endcase
                    end
                end
                `Type_S: begin
                    wb_enable = `Disable;
                    wb_addr = `ZeroRegAddr;
                    wb_data = `ZeroWord;
                    if (mem_access_stat == `DHandled) begin
                        mem_access_enable = `Disable;
                        mem_access_sel = `Read;
                        mem_access_type = `Word;
                        mem_access_addr = `ZeroWord;
                        mem_access_dout = `ZeroWord;
                        stall_request = `Disable;
                    end
                    else begin
                        mem_access_enable = `Enable;
                        mem_access_sel = `Write;
                        mem_access_addr = rd_data;
                        case (opname)
                            `SW: begin
                                mem_access_dout = s_data;
                                mem_access_type = `Word;
                            end
                            `SH: begin
                                mem_access_dout = {{16{1'b0}}, s_data[15 : 0]};
                                mem_access_type = `Half;
                            end
                            `SB: begin
                                mem_access_dout = {{24{1'b0}}, s_data[ 7 : 0]};
                                mem_access_type = `Byte;
                            end
                            default: begin
                                mem_access_dout = `ZeroWord;
                                mem_access_type = `Word;
                            end
                        endcase
                        stall_request = `Enable;
                    end
                end
                `Type_R,`Type_I,`Type_IJ,`Type_U,`Type_UJ: begin
                    wb_enable = `Enable;
                    wb_addr = rd_addr;
                    wb_data = rd_data;
                    mem_access_enable = `Disable;
                    mem_access_sel = `Read;
                    mem_access_type = `Word;
                    mem_access_addr = `ZeroWord;
                    mem_access_dout = `ZeroWord;
                    stall_request = `Disable;
                end
                default: begin
                    wb_enable = `Disable;
                    wb_addr = `ZeroRegAddr;
                    wb_data = `ZeroWord;
                    mem_access_enable = `Disable;
                    mem_access_sel = `Read;
                    mem_access_type = `Word;
                    mem_access_addr = `ZeroWord;
                    mem_access_dout = `ZeroWord;
                    stall_request = `Disable;
                end
            endcase
        end
    end

endmodule