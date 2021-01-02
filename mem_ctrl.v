module MEM_CTRL(
    input wire clk,
    input wire rst,

    // from IF
    input wire ctrl_request_enable_if,
    input wire [`RAMAddrLen - 1 : 0] ctrl_request_addr_if,

    // from MEM
    input wire ctrl_request_enable_mem,
    input wire ctrl_func_sel,
    input wire [`MSelLen - 1 : 0] ctrl_rw_type,
    input wire [`RAMAddrLen - 1 : 0] ctrl_request_addr_mem,
    input wire [`RegLen - 1 : 0] ctrl_request_dout,

    // memory access
    input wire [7 : 0] ram_access_data,
    output reg ram_access_sel,
    output reg [`RAMAddrLen - 1 : 0] ram_access_addr,
    output reg [7 : 0] ram_access_dout, 

    // to IF or MEM
    output reg [`RegLen - 1 : 0] ctrl_request_data,
    output reg [`RAMAddrLen - 1 : 0] mem_ctrl_handled_addr,
    output reg [`MCtrlStatLen - 1 : 0] mem_ctrl_stat
);

    parameter F=0, W0=1, W1=2, W2=3, W3=4, WE=5; // Free, Work Stage 0-3, Work Ended
    reg [2 : 0] stage, next;
    parameter N=0, RI=1, RD=2, WD=3; // Null, Read Inst, Read Data, Write Data
    reg [1 : 0] state;

    reg [`MSelLen - 1 : 0] ram_access_type;
    reg [`RegLen - 1 : 0] ram_dout;
    reg [`RAMAddrLen - 1 : 0] cur_ram_addr;

    always @(*)
        case (stage)
            F:  next = W0;
            W0: next = ((ram_access_type == `Byte) ? WE : W1);
            W1: next = ((ram_access_type == `Half) ? WE : W2);
            W2: next = W3;
            W3: next = WE;
            WE: next = F ;
            default: next = F;
        endcase

    always @(posedge clk) begin
        if (rst == `Enable) begin
            stage <= F;
            state <= N;
            mem_ctrl_stat <= `Free;
            mem_ctrl_handled_addr <= `ZeroWord;
            ctrl_request_data <= `ZeroWord;
            ram_access_sel <= `Read;
            ram_access_addr <= `ZeroWord;
            cur_ram_addr <= `ZeroWord;
            ram_dout <= `ZeroWord;
            ram_access_dout <= 8'h0;
            ram_access_type <= `Word;
        end
        else if (stage == F) begin
            if (ctrl_request_enable_mem == `Enable) begin
                stage <= next;
                mem_ctrl_stat <= `Busy;
                ram_access_sel <= `Read;
                ram_access_type <= ctrl_rw_type;
                cur_ram_addr <= ctrl_request_addr_mem;
                if (ctrl_func_sel == `Read) begin
                    state <= RD;
                    ram_access_addr <= ctrl_request_addr_mem;
                    ram_dout <= `ZeroWord;
                end
                else begin
                    state <= WD;
                    ram_dout <= ctrl_request_dout;
                end
                // ctrl_request_data <= `ZeroWord;
            end
            else if (ctrl_request_enable_if == `Enable) begin
                stage <= next;
                mem_ctrl_stat <= `Busy;
                ram_access_sel <= `Read;
                state <= RI;
                ram_access_type <= `Word;
                ram_access_addr <= ctrl_request_addr_if;
                cur_ram_addr <= ctrl_request_addr_if;
                ram_dout <= `ZeroWord;
            end
            else begin
                mem_ctrl_stat <= `Free;
            end
        end
        else if (state == RI) begin
            if (ctrl_request_addr_if != cur_ram_addr) begin
                stage <= W0;
                state <= RI;
                ram_access_sel <= `Read;
                ram_access_addr <= ctrl_request_addr_if;
                cur_ram_addr <= ctrl_request_addr_if;
            end
            else begin
                if (stage == W0) begin
                    stage <= next;
                    ram_access_addr <= ram_access_addr + 1'b1;
                end
                else if (stage == W1) begin
                    stage <= next;
                    ram_access_addr <= ram_access_addr + 1'b1;
                    ctrl_request_data[ 7 :  0] <= ram_access_data;
                end
                else if (stage == W2) begin
                    stage <= next;
                    ram_access_addr <= ram_access_addr + 1'b1;
                    ctrl_request_data[15 :  8] <= ram_access_data;
                end
                else if (stage == W3) begin
                    stage <= next;
                    ctrl_request_data[23 : 16] <= ram_access_data;
                end
                else if (stage == WE) begin
                    stage <= next;
                    ctrl_request_data[31 : 24] <= ram_access_data;
                    state <= N;
                    mem_ctrl_stat <= `IHandled;
                    mem_ctrl_handled_addr <= cur_ram_addr;
                end
            end
        end
        else if (state == RD) begin
            if (stage == W0) begin
                stage <= next;
                ram_access_addr <= ram_access_addr + 1'b1;
            end
            else if (stage == W1) begin
                stage <= next;
                ram_access_addr <= ram_access_addr + 1'b1;
                ctrl_request_data[ 7 :  0] <= ram_access_data;
            end
            else if (stage == W2) begin
                stage <= next;
                ram_access_addr <= ram_access_addr + 1'b1;
                ctrl_request_data[15 :  8] <= ram_access_data;
            end
            else if (stage == W3) begin
                stage <= next;
                ctrl_request_data[23 : 16] <= ram_access_data;
            end
            else if (stage == WE) begin
                stage <= next;
                case (ram_access_type)
                    `Word: ctrl_request_data[31 : 24] <= ram_access_data;
                    `Half: ctrl_request_data[15 :  8] <= ram_access_data;
                    `Byte: ctrl_request_data[ 7 :  0] <= ram_access_data;
                    default:;
                endcase
                state <= N;
                mem_ctrl_stat <= `DHandled;
                mem_ctrl_handled_addr <= cur_ram_addr;
            end
        end
        else if (state == WD) begin
            if (stage == W0) begin
                stage <= next;
                ram_access_sel <= `Write;
                ram_access_addr <= cur_ram_addr;
                ram_access_dout <= ram_dout[ 7 :  0];
            end
            else if (stage == W1) begin
                stage <= next;
                ram_access_addr <= ram_access_addr + 1'b1;
                ram_access_dout <= ram_dout[15 :  8];
            end
            else if (stage == W2) begin
                stage <= next;
                ram_access_addr <= ram_access_addr + 1'b1;
                ram_access_dout <= ram_dout[23 : 16];
            end
            else if (stage == W3) begin
                stage <= next;
                ram_access_addr <= ram_access_addr + 1'b1;
                ram_access_dout <= ram_dout[31 : 24];
            end
            else if (stage == WE) begin
                stage <= next;
                state <= N;
                ram_access_sel <= `Read;
                ram_access_addr <= `ZeroWord;
                mem_ctrl_stat <= `DHandled;
                mem_ctrl_handled_addr <= cur_ram_addr;
            end
        end
    end

endmodule