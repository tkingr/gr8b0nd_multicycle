 // Basic sizes
`define WORDSIZE 15:0
`define TAGWORDSIZE 16:0
`define OP  4:0
`define REGCOUNT 15:0
`define REGSIZE 15:0
`define MEMSIZE 65535:0
`define MEMMAX 65535
`define UPPER16 15:8
`define LOWER16 7:0
 
// Field placements and values
`define is_const 15
`define msb_8 7
`define op0 15:12
`define op1 15:8
`define rd 3:0
`define rs 7:4
`define imm 10:4
 
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

// States (not opcodes)
`define Start 8'h02
`define Decode 8'h03
`define ExecuteGeneral 8'h04
`define ExecuteConstant 8'h05
 
module ALU(
        output [`WORDSIZE] ALU_out,
        output CarryOut, // Flag indicating overflow        
        input [`WORDSIZE] A, B, // A treated as source, B treated as destination
        input [`LOWER16] ALU_select // We are using same # as 8-bit op_1 field
    );
    reg [15:0] ALU_result;
    wire [16:0] temp;
    assign ALU_out = ALU_result; // Wire tied to output reg
    assign temp = {1'b0, A} + {1'b0, B};
    assign CarryOut = temp[16]; // Carryout flag
 
    always @(*) begin
        case(ALU_select)

            // 2-register instructions
            `OPaddi:
                ALU_result = (A + B);
            `OPaddii: begin
                ALU_result[`UPPER16] = A[`UPPER16] + B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] + B[`LOWER16];
            end
            `OPmuli:
                ALU_result = (A * B);
            `OPmulii: begin
                ALU_result[`UPPER16] = A[`UPPER16] * B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] * B[`LOWER16];
            end
            `OPshi:
                ALU_result = (A > 0) ? (B << A) : (B >> -A);
            `OPshii: begin
                ALU_result[`UPPER16] = (A[`UPPER16] > 0) ? (B[`UPPER16] << A[`UPPER16]) : (B[`UPPER16] >> -A[`UPPER16]);
                ALU_result[`LOWER16] = (A[`LOWER16] > 0) ? (B[`LOWER16] << A[`LOWER16]) : (B[`LOWER16] >> -A[`LOWER16]);
            end
            `OPslti:
                ALU_result = (B < A);
            `OPsltii: begin
                ALU_result[`UPPER16] = (B[`UPPER16] < A[`UPPER16]);
                ALU_result[`LOWER16] = (B[`LOWER16] < A[`LOWER16]);
            end
            `OPaddp:
                ALU_result = (A + B);
            `OPaddpp: begin
                ALU_result[`UPPER16] = A[`UPPER16] + B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] + B[`LOWER16];
            end
            `OPmulp:
                ALU_result = (A * B);
            `OPmulpp: begin
                ALU_result[`UPPER16] = A[`UPPER16] * B[`UPPER16];
                ALU_result[`LOWER16] = A[`LOWER16] * B[`LOWER16];    
            end
            `OPand:
                ALU_result = A & B;
            `OPor:
                ALU_result = A | B;
            `OPxor:
                ALU_result = A ^ B;

            // 1-register instructions
            `OPanyi:
                ALU_result = (B) ? -1 : 0;
            `OPanyii: begin
                ALU_result[`UPPER16] = (B[`UPPER16]) ? -1 : 0;
                ALU_result[`LOWER16] = (B[`LOWER16]) ? -1 : 0;
            end
            `OPnegi:
                ALU_result = -(B);
            `OPnegii: begin
                ALU_result[`UPPER16] = -B[`UPPER16];
                ALU_result[`LOWER16] = -B[`LOWER16];
            end
            `OPi2p:
                ALU_result = B;
            `OPii2pp:
                ALU_result = B;
            `OPp2i:
                ALU_result = B;
            `OPpp2ii:
                ALU_result = B;
            `OPinvp:
                ALU_result = (1 / B);
            `OPinvpp: begin
                ALU_result[`UPPER16] = (1 / B[`UPPER16]);
                ALU_result[`LOWER16] = (1 / B[`LOWER16]);
            end
            `OPnot:
                ALU_result = ~(B);
            default: ALU_result = B;
        endcase
    end
endmodule

module processor(halt, reset, clk);
    output reg halt;
    input reset, clk;
    reg[`REGCOUNT] register[`REGSIZE];
    wire[`WORDSIZE] alu_output;
    wire alu_carry;
    reg[`WORDSIZE] text[`MEMSIZE];
    reg[`WORDSIZE] data[`MEMSIZE];
    reg[`WORDSIZE] pc = 0;
    reg[`WORDSIZE] inst_reg;
    reg[`imm] sys;
    reg[`rd] rs_num;
    reg[`rd] rd_num;
    reg[`imm] imm;
    reg[`op0] op_0;
    reg[`op1] op_1;
    reg[`op1] state;

    ALU my_alu(alu_output, alu_carry, register[rs_num], register[rd_num], op_1);

    always @(posedge reset) begin
        halt <= 0;
        pc <= 0;
        state <= `Start;
    // Initializing instructions with readmem/h
        register[1] = 0;
        register[2] = 0;
        register[3] = 30;
        data[0] = 420;
        $readmemh0(text);
    end

    always @(posedge clk) begin
        case (state)
            `Start: begin 
                inst_reg <= text[pc];
                pc <= pc + 1;                 
                state <= `Decode;
                end
            `Decode: begin
                op_1 <= inst_reg[`op1];
                op_0 <= inst_reg[`op0];
                rs_num <= inst_reg[`rs];
                rd_num <= inst_reg[`rd];
                imm <= inst_reg[`imm];
                state <= (inst_reg[`is_const]) ? (`ExecuteConstant) : (`ExecuteGeneral);
                end
            `ExecuteConstant: begin
                case (op_0)
                    `OPbz: begin
                        if (register[rd_num] == 0)
                            pc <= imm;
                        end
                    `OPbnz: begin
                        if (register[rd_num] != 0)
                            pc <= imm;
                        end
                    `OPci8: begin
                        if (imm & 8'h80)
                            register[rd_num] <= (16'hff00 | (imm & 8'hff));
                        else
                            register[rd_num] <= (16'h0000 | (imm & 8'hff));
                        end
                    default: register[rd_num] <= alu_output;
                endcase
                state <= `Start;
                end
            `ExecuteGeneral: begin
                case (op_1)
                    `OPld: begin
                        if (register[rs_num] > `MEMMAX)
                            halt <= 1;
                        else
                            register[rd_num] <= data[register[rs_num]];
                        end
                    `OPst: begin
                        if (register[rs_num] > `MEMMAX)
                            halt <= 1;
                        else
                            data[register[rs_num]] <= register[rd_num];
                        end
                    `OPjr: begin
                        if (register[rs_num] > `MEMMAX)
                            halt <= 1;
                        else
                            pc <= register[rd_num];
                        end
                    `OPtrap: 
                        $display("This is a trap!");
                    default: register[rd_num] <= alu_output;
                endcase
                state <= `Start;
                end
            default: begin halt <= 1; end
        endcase
    end
endmodule

module tb_processor;
    reg reset = 0;
    reg clk = 0;
    wire halted;

    processor my_processor(halted, reset, clk);

    initial begin
        $dumpfile;
        $dumpvars(0, my_processor);
        #10 reset = 1;
        #10 reset = 0;
        while (!halted) begin
            #10 clk = 1;
            #10 clk = 0;
        end
        $finish;
    end
endmodule

/*
module tb_alu;
    //Inputs
    reg[`WORDSIZE] A,B;
    reg[`LOWER16] ALU_select;

    //Outputs
    wire[`WORDSIZE] ALU_out;
    wire CarryOut;
    // Verilog code for ALU
    integer i;
    ALU test_unit(
                ALU_out, // ALU 8-bit Output
                CarryOut, // Carry Out Flag             
                A,B,  // ALU 8-bit Inputs                 
                ALU_select// ALU Selection
        );
        initial begin
        // hold reset state for 100 ns.
        A = 16'h08;
        B = 16'h02;
        ALU_select = 8'h70;
        
        for (i=0;i<=2;i=i+1)
        begin
        #10;
        $display("OPcode: %h ALU Output: %b ALU Carry: %b", ALU_select, ALU_out, CarryOut);
        ALU_select = ALU_select + 8'h01;
        end
        
        A = 16'hF6;
        B = 16'h0A;
        
        end
endmodule
*/