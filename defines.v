`define ZeroWord 32'h00000000
`define ZeroRegAddr 5'b00000

`define RegAddrLen 5
`define RegLen 32
`define RegNum 32

`define RAMAddrLen 32
`define InstLen 32

`define Enable 1'b1
`define Disable 1'b0

// cache
// - icache (DM)
`define ICacheLines     128
`define ICacheLineSize   42
// -- icache fields
`define IValid_Bit       41
`define ICache_Tag_T     40
`define ICache_Tag_H     17
`define ICache_Tag_L      9
`define ICache_Index_H    8
`define ICache_Index_L    2
// - dcache (4-way SA)
`define DCacheLines      64
`define DCacheBlockSize 128
`define DCacheEntrySize 136 // Block Size 128 + Tag Size 8
`define DCacheLineSize  555
// -- dcache fields
`define DRef_H          554
`define DRef_L          552
`define DDirty_H        551
`define DDirty_L        548
`define DValid_H        547
`define DValid_L        544
`define DCache_Tag_T    135
`define DCache_Tag_B    128
`define DCache_Tag_H     17
`define DCache_Tag_L     10
`define DCache_Index_H    9
`define DCache_Index_L    4

// memory control
`define Read  1'b0
`define Write 1'b1
// - memory control status
`define MCtrlStatLen 2
`define Free     2'b00
`define Busy     2'b01
`define IHandled 2'b10
`define DHandled 2'b11
// - memory control function selection
`define MSelLen 2
`define Word 2'b00
`define Half 2'b01
`define Byte 2'b10

// stall
`define StallLevelLen 2
`define Stall_All       2'b11
`define Stall_Issue     2'b10
`define Stall_Decode    2'b01
`define Stall_Null      2'b00

// jump
`define JumpInfoLen 2
`define Jump_ID     0
`define Jump_EX     1

// insts
`define OpCodeLen 7
// - optype
`define OpTypeLen 3
`define Type_R  3'b000
`define Type_I  3'b001
`define Type_IL 3'b010
`define Type_IJ 3'b011
`define Type_S  3'b100
`define Type_SB 3'b101
`define Type_U  3'b110
`define Type_UJ 3'b111
// - opname
`define OpLen 4
// -- R
`define ADD     4'b0000
`define SUB     4'b1000
`define SLL     4'b0001
`define SRL     4'b0101
`define SRA     4'b1101
`define SLT     4'b0010
`define SLTU    4'b0011
`define XOR     4'b0100
`define OR      4'b0110
`define AND     4'b0111
// -- I
`define ADDI    4'b0000
`define SLTI    4'b0010
`define SLTIU   4'b0011
`define XORI    4'b0100
`define ORI     4'b0110
`define ANDI    4'b0111
`define SLLI    4'b0001
`define SRLI    4'b0101
`define SRAI    4'b1101
// -- I-Load
`define LW      4'b0010
`define LH      4'b0001
`define LB      4'b0000
`define LHU     4'b0101
`define LBU     4'b0100
// -- I-Jump
`define JALR    4'b0000
// -- S
`define SW      4'b0010
`define SH      4'b0001
`define SB      4'b0000
// -- S-Branch
`define BEQ     4'b0000
`define BNE     4'b0001
`define BLT     4'b0100
`define BGE     4'b0101
`define BLTU    4'b0110
`define BGEU    4'b0111
// -- U
`define LUI     4'b0000
`define AUIPC   4'b0001
// -- U-Jump
`define JAL     4'b0000