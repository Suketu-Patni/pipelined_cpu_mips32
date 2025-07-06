/*
procedure for running programs on processor

1. load program from specific memory address
2. initialize pc with the starting address of the program
3. execution continues until hlt encountered
4. print results from memory to verify operation
*/

// example 1
/*
add three numbers 10, 20, 30 
as stored in processor registers

1. initialize register r1 with 10,
2. initialize r2 with 20
3. initialize r3 with 25
4. add the three numbers and store the partial sums
   in r4 and r5

program looks like

1. addi r1, r0, 10
(001010 00000 00001 0000000000001010)
2. addi r2, r0, 20
(001010 00000 00010 0000000000010100)
3. addi r3, r0, 25
(001010 00000 00011 0000000000011001)
4. add r4, r1, r2
(000000 00001 00010 00100 00000 000000)
5. add r5, r4, r3
(000000 00100 00011 00101 00000 000000)
6. hlt
(111111 00000 00000 00000 00000 000000)

note that since we are using two clocks, 
delaying hazards by one instruction is sufficient
between instructions 3 and 4 and two between 4 and 5
let the dummy instruction be 
or r7, r7, r7
(000011 00111 00111 0111100000000000)
*/

// // program 1

// module test_mips32;
//     reg clk1, clk2;

//     integer k1, k2;

//     pipe_mips32 mips(clk1, clk2);

//     initial begin
//         clk1 = 1'b0; clk2 = 1'b0;
//         repeat (20)
//             begin
//                 #5 clk1 = 1'b1; clk1 = 1'b0;
//                 #5 clk2 = 1'b1; clk2 = 1'b0;
//             end
//     end

//     initial begin
//         for (k1=0; k1 < 31; k1=k1+1)
//             begin
//                 mips.Reg[k1] = k1;
//             end

        
//         mips.mem[0] = 32'b00101000000000010000000000001010; //instr1
//         mips.mem[1] = 32'b00101000000000100000000000010100; //instr2
//         mips.mem[2] = 32'b00101000000000110000000000011001; //instr3
//         mips.mem[3] = 32'b00001100111001110111100000000000; //dummy
//         mips.mem[4] = 32'b00000000001000100010000000000000; //instr4
//         mips.mem[5] = 32'b00001100111001110111100000000000; //dummy
//         mips.mem[6] = 32'b00000000100000110010100000000000; //instr5
//         mips.mem[7] = 32'b11111100000000000000000000000000; //instr6
        
//         mips.halted = 0;
//         mips.pc = 0;
//         mips.taken_branch = 0;

//         #280 for (k2=0; k2 < 6; k2=k2+1)
//             begin
//                 $display("R%1d - %2d", k2, mips.Reg[k2]);
//             end

//     end

//     initial begin
//         $dumpfile ("mips.vcd");
//         $dumpvars (0, test_mips32);
//         #300 $finish;
//     end
// endmodule

// // program 2
// /*
// load a word stored in memory location 120, add 45 to
// it, and store the result in memory location 121

// 1. addi r1, r0, 120
// (001010 00000 00001 0000000001111000)
// 2. lw r2, 0(r1)
// (001000 00001 00010 0000000000000000)
// 3. addi r2, r2, 45
// (001010 00010 00010 0000000000101101)
// 4. sw r2, 1(r1)
// (001001 00010 00001 0000000000000001)
// 5. hlt
// (111111 00000 00000 00000 00000 000000)

// let the dummy be or r3, r3, r3
// */

// module test_mips32;
//     reg clk1, clk2;

//     integer k1;

//     pipe_mips32 mips(clk1, clk2);

//     initial begin
//         clk1 = 1'b0; clk2 = 1'b0;
//         repeat (50)
//             begin
//                 #5 clk1 = 1'b1; clk1 = 1'b0;
//                 #5 clk2 = 1'b1; clk2 = 1'b0;
//             end
//     end

//     initial begin
//         for (k1=0; k1 < 31; k1=k1+1)
//             begin
//                 mips.Reg[k1] = k1;
//             end

        
//         mips.mem[0] = 32'h28010078; //instr1
//         mips.mem[1] = 32'h0c631800; //dummy
//         mips.mem[2] = 32'h20220000; //instr2
//         mips.mem[3] = 32'h0c631800; //dummy
//         mips.mem[4] = 32'h2842002d; //instr3
//         mips.mem[5] = 32'h0c631800; //dummy
//         mips.mem[6] = 32'h24220001; //instr4
//         mips.mem[7] = 32'hfc000000; //instr5

//         mips.mem[120] = 85;
        
//         mips.halted = 0;
//         mips.pc = 0;
//         mips.taken_branch = 0;

//         #500 $display("mem[120]: %4d \nmem[121]: %4d", mips.mem[120], mips.mem[121]);

//     end

//     initial begin
//         $dumpfile ("mips2.vcd");
//         $dumpvars (0, test_mips32);
//         #600 $finish;
//     end
// endmodule

// program 3
/*
compute the factorial of a number n stored
in memory location 200 and store it in 198

addi r10, r0, 200
addi r2, r0, 1
lw r3, 0(r10)
loop: mul r2, r2, r3
      subi r3, r3, 1
      bneqz r3, loop
      // to get to loop, we need to add -3 to incremented
      // pc
      // (maybe -4 to accomodate for dummy instructions)
      // so we encode it as
      // 001101 00011 00000 1111111111111101
sw r2, -2(r10) // imm is 1111111111111110
hlt

let the dummy be or r20, r20, r20
*/

module test_mips32;
    reg clk1, clk2;

    integer k1;

    pipe_mips32 mips(clk1, clk2);

    initial begin
        clk1 = 1'b0; clk2 = 1'b0;
        repeat (50)
            begin
                #5 clk1 = 1'b1; clk1 = 1'b0;
                #5 clk2 = 1'b1; clk2 = 1'b0;
            end
    end

    initial begin
        for (k1=0; k1 < 31; k1=k1+1)
            begin
                mips.Reg[k1] = k1;
            end

        
        mips.mem[0] = 32'h280a00c8; //instr1
        mips.mem[1] = 32'h28020001; //instr2
        mips.mem[2] = 32'h0e94a000; //dummy
        mips.mem[3] = 32'h21430000; //instr3
        mips.mem[4] = 32'h0e94a000; //dummy
        mips.mem[5] = 32'h14431000; //instr4
        mips.mem[6] = 32'h2c630001; //instr5
        mips.mem[7] = 32'h0e94a000; //dummy
        mips.mem[8] = 32'h3460fffc; //instr6: bneqz with -4 offset
        mips.mem[9] = 32'h2542fffe; //instr7
        mips.mem[10] = 32'hfc000000; //instr8

        mips.mem[200] = 7; // find 7!
        
        mips.halted = 0;
        mips.pc = 0;
        mips.taken_branch = 0;

        #2000 $display("mem[200]: %2d \nmem[198]: %6d", mips.mem[200], mips.mem[198]);

    end

    initial begin
        $dumpfile ("mips3.vcd");
        $dumpvars (0, test_mips32);
        $monitor ("R2: %4d", mips.Reg[2]);
        #3000 $finish;
    end
endmodule

/*
-instruction set is turing complete
-until now we have only avoided control hazards
 by "taken_branch" and data hazards by inserting 
 dummy instructions this is typically done by 
 compilers (software)
-we have done it behaviourally, but for synthesis, 
 structural is preferred. then, the program will
 be generating the control signals for the pipelined
 datapath in a proper sequence
*/