 // Basic sizes
`define WORD 15:0
`define OP  4:0
`define REGSIZE 15:0
`define MEMSIZE 65535:0
`define UPPER16 15:8
`define LOWER16 7:0
 
// Field placements and values
`define cbit [15]
`define op0 [15:11]
`define op1 [15:7]
`define rd [3:0]
`define rs [7:4]
`define imm [10:4]
 
// Branch Instructions
`define OPbz 4'he
`define OPbnz 4'hf
 
// Constant Instructions
`define OPci8 4'hb
`define OPcii 4'hc
`define OPcup 4'hd
 
// 2 Register Instructions
`define OPaddi 8'h70
`define OPaddii 8'h71
`define OPmuli 8'h72
`define OPmulii 8'h73
`define OPshi 8'h74
`define OPshii 8'h75
`define OPslti 8'h76
`define OPsltii 8'h77
`define OPaddp 8'h60
`define OPaddpp 8'h61
`define OPmulp 8'h62
`define OPmulpp 8'h63
`define OPand 8'h50
`define OPor 8'h51
`define OPxor 8'h52
`define OPld 8'h40
`define OPst 8'h41
 
// 1 Register Instructions
`define OPanyi 8'h30
`define OPanyii 8'h31
`define OPnegi 8'h32
`define OPnegii 8'h33
`define OPi2p 8'h20
`define OPii2pp 8'h21
`define OPp2i 8'h22
`define OPpp2ii 8'h23
`define OPinvp 8'h24
`define OPinvpp 8'h25
`define OPnot 8'h10
`define OPjr 8'h01
 
// Trap Instruction
`define OPtrap 8'h00
 
module ALU(
        input [15:0] A, B, // A treated as source, B treated as destination
        input [7:0] ALU_select, // We are using same # as 8-bit op field
        output [15:0] ALU_out,
        output CarryOut // Flag indicating overflow
    );
    reg [7:0] ALU_result;
    wire [16:0] temp;
    assign ALU_out = ALU_result; // Wire tied to output reg
    assign temp = {1'b0, A} + {1'b0, B};
    assign CarryOut = temp[16]; // Carryout flag
 
    always @(*)
    begin
        case(ALU_select)
            `OPaddi:
                ALU_result = (A + B);
            `OPaddii:
            begin
                ALU_result[`UPPER16] = A[`UPPER16] + B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] + B[`LOWER16];
            end
            `OPmuli:
                ALU_result = (A * B);
            `OPmulii:
            begin
                ALU_result[`UPPER16] = A[`UPPER16] * B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] * B[`LOWER16];
            end
            `OPshi:
                ALU_result = (A > 0) ? (ALU_result << A) : (ALU_result >> -A);
            `OPshii:
            begin
                ALU_result[`UPPER16] = (A[`UPPER16] > 0) ? (B[`UPPER16] << A[`UPPER16]) : (B[`UPPER16] >> -A[`UPPER16]);
                ALU_result[`LOWER16] = (A[`LOWER16] > 0) ? (B[`LOWER16] << A[`LOWER16]) : (B[`LOWER16] >> -A[`LOWER16]);
            end
            `OPslti:
                ALU_result = (B < A);
            `OPsltii:
            begin
                ALU_result[`UPPER16] = (B[`UPPER16] < A[`UPPER16]);
                ALU_result[`LOWER16] = (B[`LOWER16] < A[`LOWER16]);
            end
            `OPaddp:
                ALU_result = (A + B);
            `OPaddpp:
            begin
                ALU_result[`UPPER16] = A[`UPPER16] + B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] + B[`LOWER16];
            end
            `OPmulp:
                ALU_result = (A * B);
            `OPmulpp:
            begin
                ALU_result[`UPPER16] = A[`UPPER16] * B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] * B[`LOWER16];    
            end
            `OPand:
                ALU_result = A&B;
            `OPor:
                ALU_result = A|B;
            `OPxor:
                ALU_result = A^B;
            `OPnot:
                ALU_result = ~B;
            `OPnegi:
                ALU_result = -B;
            `OPnegii:
            begin
                ALU_result[`UPPER16] = -B[`UPPER16];
                ALU_result[`LOWER16] = -B[`LOWER16];
            end
            default: ALU_result = A + B;
        endcase
    end
endmodule

module tb_alu;
//Inputs
 reg[15:0] A,B;
 reg[7:0] ALU_select;

//Outputs
 wire[15:0] ALU_out;
 wire CarryOut;
 // Verilog code for ALU
 integer i;
 ALU test_unit(
            A,B,  // ALU 8-bit Inputs                 
            ALU_select,// ALU Selection
            ALU_out, // ALU 8-bit Output
            CarryOut // Carry Out Flag
     );
    initial begin
    // hold reset state for 100 ns.
      A = 16'h09;
      B = 16'h00;
      ALU_select = 8'h70;
      
      for (i=0;i<=7;i=i+1)
      begin
       #10;
       $display("OPcode: %h ALU Output: %d ALU Carry: %b", ALU_select, ALU_out, CarryOut);
       ALU_select = ALU_select + 8'h01;
      end;
      
      A = 16'hF6;
      B = 16'h0A;
      
    end
endmodule