module REGFILE (
    input wire clk,
    input wire rst,
    // read1
    input wire read1_enable,
    input wire [`RegAddrLen - 1 : 0] read1_addr,
    
    // read2
    input wire read2_enable,
    input wire [`RegAddrLen - 1 : 0] read2_addr,
    
    // write
    input wire write_enable,
    input wire [`RegAddrLen - 1 : 0] write_addr,
    input wire [`RegLen - 1 : 0] write_data,

    output reg [`RegLen - 1 : 0] read1_data,
    output reg [`RegLen - 1 : 0] read2_data
);

    reg [`RegLen - 1 : 0] regs [`RegNum - 1 : 0];
    integer i;

    // write
    always @(posedge clk) begin
        if (rst == `Enable) begin
            for (i = 0; i < `RegNum; i = i + 1) begin
                regs[i] <= `ZeroWord;
            end
        end
        else if (write_enable==`Enable && write_addr!=`ZeroRegAddr)
            regs[write_addr] <= write_data;
    end

    // read
    always @(*) begin
        if (rst==`Disable && read1_enable==`Enable) begin
            if (read1_addr==`ZeroRegAddr)
                read1_data = `ZeroWord;
            else if (write_enable==`Enable && read1_addr==write_addr)
                read1_data = write_data;
            else
                read1_data = regs[read1_addr];
        end
        else
            read1_data = `ZeroWord;
    end
    always @(*) begin
        if (rst==`Disable && read2_enable==`Enable) begin
            if (read2_addr==`ZeroRegAddr)
                read2_data = `ZeroWord;
            else if (write_enable==`Enable && read2_addr==write_addr)
                read2_data = write_data;
            else
                read2_data = regs[read2_addr];
        end
        else
            read2_data = `ZeroWord;
    end

endmodule