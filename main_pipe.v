// see notebook for full explanation

module pipe_mips32(clk1, clk2);
    input clk1, clk2; // two phase clock
    reg [31:0] pc, if_id_ir, if_id_npc;
    reg [31:0] id_ex_ir, id_ex_npc, id_ex_a, id_ex_b, id_ex_imm;
    reg [2:0] id_ex_type, ex_mem_type, mem_wb_type;
    reg [31:0] ex_mem_ir, ex_mem_aluout, ex_mem_b;
    reg ex_mem_cond;
    reg [31:0] mem_wb_ir, mem_wb_aluout, mem_wb_lmd;
    reg [31:0] Reg [0:31];
    reg [31:0] mem [0:1023];

    parameter add = 6'd0, sub = 6'd1, and_ = 6'd2, or_ = 6'd3, 
    slt = 6'd4, mul = 6'd5, hlt = 6'd63, lw = 6'd8, 
    sw = 6'd9, addi = 6'd10, subi = 6'd11, slti = 6'd12,
    bneqz = 6'd13, beqz = 6'd14;

    parameter rr_alu = 3'b000, rm_alu = 3'b001,
    load = 3'b010, store = 3'b011, branch = 3'b100,
    halt = 3'b101;
    // some "types" of instructions (for convenience
    // in determining what to do; these will be stored
    // in the "_type" registers)

    // rr-alu: register-register alu type
    // rm-alu: register-immediate alu type

    reg halted;
    reg taken_branch;

    // IF stage
    always @(posedge clk1)
        if (halted == 0)
            begin
                if (((ex_mem_ir[31:26] == beqz) && (ex_mem_cond == 1)) ||
                    ((ex_mem_ir[31:26] == bneqz) && (ex_mem_cond == 0)))
                    begin
                        if_id_ir <= #2 mem[ex_mem_aluout];
                        taken_branch <= #2 1'b1;
                        // taken_branch will be used in mem and wb
                        // stages
                        if_id_npc <= #2 ex_mem_aluout + 1;
                        pc <= #2 ex_mem_aluout + 1;
                    end
                else
                    begin
                        if_id_ir <= #2 mem[pc];
                        if_id_npc <= #2 pc + 1;
                        pc <= #2 pc + 1;
                    end
            end

    // ID
    always @(posedge clk2)
        if (halted == 0)
            begin
                // rs: check if rs is 0. if it is, 
                // assign 0 directly since 0 reg
                // only holds 0
                if (if_id_ir[25:21] == 5'b0)
                    id_ex_a <= 0;
                else
                    id_ex_a <= #2 Reg[if_id_ir[25:21]];

                // rt: same as with rs
                if (if_id_ir[20:16] == 5'b0)
                    id_ex_b <= 0;
                else
                    id_ex_b <= #2 Reg[if_id_ir[20:16]];

                id_ex_npc <= if_id_npc;
                id_ex_ir <= if_id_ir;
                id_ex_imm <= {{16{if_id_ir[15]}}, if_id_ir[15:0]};
                // sign extended
                case (if_id_ir[31:26])
                    add, sub, and_, or_, slt, mul: id_ex_type <= #2 rr_alu;
                    addi, subi, slti: id_ex_type <= #2 rm_alu;
                    lw: id_ex_type <= #2 load;
                    sw: id_ex_type <= #2 store;
                    bneqz, beqz: id_ex_type <= #2 branch;
                    hlt: id_ex_type <= #2 halt;
                    default: id_ex_type <= #2 halt; 
                    // invalid opcode => we should halt
                endcase

            end

    // EX
    always @(posedge clk1)
        if (halted == 0)
            begin
                ex_mem_type <= #2 id_ex_type;
                ex_mem_ir <= #2 id_ex_ir;
                taken_branch <= #2 0;
                // ### important! all instructions after the
                // 2 following a branch instruction should
                // be allowed to change state since pc has 
                // correctly been updated before they
                // were fetched

                case (id_ex_type)
                    rr_alu:
                        begin
                            case (id_ex_ir[31:26])
                                add: ex_mem_aluout <= #2 id_ex_a + id_ex_b;
                                sub: ex_mem_aluout <= #2 id_ex_a - id_ex_b;
                                and_: ex_mem_aluout <= #2 id_ex_a & id_ex_b;
                                or_: ex_mem_aluout <= #2 id_ex_a | id_ex_b;
                                slt: ex_mem_aluout <= #2 id_ex_a < id_ex_b;
                                mul: ex_mem_aluout <= #2 id_ex_a * id_ex_b;
                                default: ex_mem_aluout <= #2 32'hxxxxxxxx;
                            endcase
                        end
                    rm_alu:
                        begin
                            case (id_ex_ir[31:26])
                                addi: ex_mem_aluout <= #2 id_ex_a + id_ex_imm;
                                subi: ex_mem_aluout <= #2 id_ex_a - id_ex_imm;
                                slti: ex_mem_aluout <= #2 id_ex_a < id_ex_imm;
                                default: ex_mem_aluout <= #2 32'hxxxxxxxx;
                            endcase
                        end
                    load, store:
                        begin
                            ex_mem_aluout <= #2 id_ex_a + id_ex_imm;
                            ex_mem_b <= #2 id_ex_b;
                        end
                    branch:
                        begin
                            ex_mem_aluout <= #2 id_ex_npc + id_ex_imm;
                            ex_mem_cond <= #2 (id_ex_a == 0);
                        end
                endcase
            end

    // MEM

    always @(posedge clk2)
        if (halted == 0)
            begin
                mem_wb_type <= #2 ex_mem_type;
                mem_wb_ir <= #2 ex_mem_ir;

                case (ex_mem_type)
                    rr_alu, rm_alu:
                        mem_wb_aluout <= #2 ex_mem_aluout;
                    load:
                        mem_wb_lmd <= #2 mem[ex_mem_aluout];
                    store:
                        if (taken_branch == 0)
                        // taken_branch == 1 => disable write
                            mem[ex_mem_aluout] <= #2 ex_mem_b;
                endcase
            end

    // WB
    always @(posedge clk1)
        begin
            if (taken_branch == 0)
            // taken_branch == 1 => disable write
                case (mem_wb_type)
                    rr_alu: Reg[mem_wb_ir[15:11]] <= #2 mem_wb_aluout; // rd
                    rm_alu: Reg[mem_wb_ir[20:16]] <= #2 mem_wb_aluout; // rt
                    load: Reg[mem_wb_ir[20:16]] <= #2 mem_wb_lmd; // rt
                    halt: halted <= #2 1'b1;
                endcase
        end

endmodule