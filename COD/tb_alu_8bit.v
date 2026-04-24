`timescale 1ns/1ps

module tb_alu_8bit;

    reg        clk, rst, start;
    reg  [1:0] opcode;
    reg  [7:0] operand_a, operand_b;

    wire [15:0] result;
    wire        carry_out, overflow, alu_done, div_zero;

    alu_8bit dut (
        .clk(clk), .rst(rst), .start(start),
        .opcode(opcode),
        .operand_a(operand_a), .operand_b(operand_b),
        .result(result),
        .carry_out(carry_out), .overflow(overflow),
        .alu_done(alu_done), .div_zero(div_zero)
    );

    initial clk = 0;
    always  #5 clk = ~clk;

    integer pass = 0, fail = 0, total = 0;

    task wait_done;
        input integer max_cycles;
        integer i;
        begin
            i = 0;
            while (!alu_done && i < max_cycles) begin @(posedge clk); i = i+1; end
            if (i >= max_cycles) $display("  !! TIMEOUT dupa %0d cicl", max_cycles);
        end
    endtask

    task run_op;
        input [1:0] op;
        input [7:0] a, b;
        begin
            @(negedge clk);
            opcode = op; operand_a = a; operand_b = b; start = 1;
            @(posedge clk); @(negedge clk);
            start = 0;
            wait_done(300);
            @(posedge clk);
        end
    endtask

    task chk;
        input [15:0] exp;
        input [7:0]  a, b;
        input [1:0]  op;
        input [63:0] name;
        begin
            total = total + 1;
            if (result === exp) begin
                pass = pass + 1;
                $display("  [OK] %s  %0d op %0d = 0x%04h", name, a, b, result);
            end else begin
                fail = fail + 1;
                $display("  [XX] %s  %0d op %0d | got=0x%04h | exp=0x%04h", name, a, b, result, exp);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_alu_8bit.vcd");
        $dumpvars(0, tb_alu_8bit);

        rst = 1; start = 0; opcode = 0; operand_a = 0; operand_b = 0;
        repeat(4) @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("=======================================================");
        $display("     TEST ALU 8-BIT STRUCTURAL");
        $display("=======================================================");

        $display("\n[ADUNARE opcode=00]");

        run_op(2'b00, 8'd15,  8'd10);  chk(16'd25,  8'd15,  8'd10,  2'b00, "ADD");
        run_op(2'b00, 8'd100, 8'd56);  chk(16'd156, 8'd100, 8'd56,  2'b00, "ADD");
        run_op(2'b00, 8'd0,   8'd0);   chk(16'd0,   8'd0,   8'd0,   2'b00, "ADD 0+0");
        run_op(2'b00, 8'd127, 8'd0);   chk(16'd127, 8'd127, 8'd0,   2'b00, "ADD 127+0");

        run_op(2'b00, 8'd255, 8'd1);
        $display("  [INFO] 255+1: result=%0d carry=%b overflow=%b [expect carry=1]",
            result[7:0], carry_out, overflow);

        run_op(2'b00, 8'd127, 8'd1);
        $display("  [INFO] 127+1 semnat: result=%0d overflow=%b [expect ov=1]",
            $signed(result[7:0]), overflow);

        $display("\n[SCADERE opcode=01]");

        run_op(2'b01, 8'd50,  8'd30);  chk(16'd20,  8'd50,  8'd30,  2'b01, "SUB");
        run_op(2'b01, 8'd100, 8'd100); chk(16'd0,   8'd100, 8'd100, 2'b01, "SUB=0");
        run_op(2'b01, 8'd200, 8'd100); chk(16'd100, 8'd200, 8'd100, 2'b01, "SUB");

        run_op(2'b01, 8'd10, 8'd20);
        $display("  [INFO] 10-20 nesemnat: result=0x%02h semnat: %0d",
            result[7:0], $signed(result[7:0]));

        $display("\n[INMULTIRE Booth Radix-2, opcode=10]");

        run_op(2'b10, 8'd3,  8'd4);   chk(16'd12,  8'd3,  8'd4,  2'b10, "MUL");
        run_op(2'b10, 8'd7,  8'd8);   chk(16'd56,  8'd7,  8'd8,  2'b10, "MUL");
        run_op(2'b10, 8'd0,  8'd255); chk(16'd0,   8'd0,  8'd255,2'b10, "MUL 0x0");
        run_op(2'b10, 8'd15, 8'd15);  chk(16'd225, 8'd15, 8'd15, 2'b10, "MUL 15x15");
        run_op(2'b10, 8'd10, 8'd10);  chk(16'd100, 8'd10, 8'd10, 2'b10, "MUL 10x10");

        run_op(2'b10, 8'hFF, 8'd3);
        $display("  [INFO] (-1)*3: result=0x%04h semnat=%0d [exp: 0xFFFD=-3]",
            result, $signed(result));

        run_op(2'b10, 8'hFB, 8'hFD);
        $display("  [INFO] (-5)*(-3): result=0x%04h semnat=%0d [exp: 0x000F=15]",
            result, $signed(result));

        $display("\n[IMPARTIRE Non-Restoring Division, opcode=11]");
        $display("  Format: result[15:8]=rest, result[7:0]=cat");

        run_op(2'b11, 8'd20, 8'd4);
        $display("  20/4  → cat=%0d rest=%0d [exp: cat=5 rest=0]",
            result[7:0], result[15:8]);
        chk({8'd0, 8'd5}, 8'd20, 8'd4, 2'b11, "DIV");

        run_op(2'b11, 8'd25, 8'd4);
        $display("  25/4  → cat=%0d rest=%0d [exp: cat=6 rest=1]",
            result[7:0], result[15:8]);
        chk({8'd1, 8'd6}, 8'd25, 8'd4, 2'b11, "DIV");

        run_op(2'b11, 8'd100, 8'd7);
        $display("  100/7 → cat=%0d rest=%0d [exp: cat=14 rest=2]",
            result[7:0], result[15:8]);

        run_op(2'b11, 8'd0, 8'd5);
        $display("  0/5   → cat=%0d rest=%0d [exp: cat=0 rest=0]",
            result[7:0], result[15:8]);

        run_op(2'b11, 8'd10, 8'd0);
        $display("  10/0  → div_zero=%b [exp: 1]", div_zero);
        total = total + 1;
        if (div_zero) begin pass = pass + 1; $display("  [OK] div by zero detectat"); end
        else          begin fail = fail + 1; $display("  [XX] div by zero NU detectat"); end

        run_op(2'b11, 8'd255, 8'd16);
        $display("  255/16→ cat=%0d rest=%0d [exp: cat=15 rest=15]",
            result[7:0], result[15:8]);

        $display("\n=======================================================");
        $display("  Total: %0d  |  OK: %0d  |  FAIL: %0d", total, pass, fail);
        if (fail == 0) $display("  *** TOATE TESTELE TRECUTE! ***");
        else           $display("  *** %0d TESTE PICAT! ***", fail);
        $display("=======================================================\n");

        #50; $finish;
    end
endmodule
