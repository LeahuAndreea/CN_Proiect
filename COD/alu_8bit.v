module alu_8bit (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [1:0] opcode,
    input  wire [7:0] operand_a,      
    input  wire [7:0] operand_b,       
    output wire [15:0] result,         
    output wire        carry_out,      
    output wire        overflow,       
    output wire        alu_done,
    output wire        div_zero
);

    wire c_load_ops;
    wire c_b_load_M, c_b_load_AQ, c_b_add, c_b_sub;
    wire c_b_shift, c_b_cnt_load, c_b_cnt_dec;
    wire c_d_load, c_d_shift, c_d_add, c_d_sub;
    wire c_d_set_q0, c_d_correct, c_d_cnt_load, c_d_cnt_dec;

    wire s_q0, s_q_neg1, s_b_cnt_zero;
    wire s_a_neg, s_d_cnt_zero, s_div_zero;

    wire [7:0] reg_A_q, reg_B_q;

    reg_8b reg_A_inst (
        .clk(clk), .reset(rst),
        .load(c_load_ops),
        .d(operand_a),
        .q(reg_A_q)
    );

    reg_8b reg_B_inst (
        .clk(clk), .reset(rst),
        .load(c_load_ops),
        .d(operand_b),
        .q(reg_B_q)
    );

    wire [7:0] add_result;
    wire       add_cout;
    adder_subtractor_8b adder_unit (
        .a(reg_A_q), .b(reg_B_q), .sub(1'b0),
        .result(add_result), .cout(add_cout), .neg()
    );

    wire [7:0] sub_result;
    wire       sub_cout;
    adder_subtractor_8b sub_unit (
        .a(reg_A_q), .b(reg_B_q), .sub(1'b1),
        .result(sub_result), .cout(sub_cout), .neg()
    );

    wire ov_a, ov_b, add_ov, sub_ov, b_inv;
    xor g_ov1 (ov_a,   reg_A_q[7],  add_result[7]);
    xor g_ov2 (ov_b,   reg_B_q[7],  add_result[7]);
    and g_ov3 (add_ov, ov_a, ov_b);

    wire ov_c, ov_d;
    not g_ov4 (b_inv,  reg_B_q[7]);
    xor g_ov5 (ov_c,   reg_A_q[7],  sub_result[7]);
    xor g_ov6 (ov_d,   b_inv,       sub_result[7]);
    and g_ov7 (sub_ov, ov_c, ov_d);

    wire [15:0] mul_product;
    booth_mult mul_unit (
        .clk(clk), .rst(rst),
        .multiplicand(reg_A_q), .multiplier(reg_B_q),
        .c_load_M(c_b_load_M),   .c_load_AQ(c_b_load_AQ),
        .c_add(c_b_add),         .c_sub(c_b_sub),
        .c_shift(c_b_shift),
        .c_cnt_load(c_b_cnt_load),.c_cnt_dec(c_b_cnt_dec),
        .s_q0(s_q0),             .s_q_neg1(s_q_neg1),
        .s_cnt_zero(s_b_cnt_zero),
        .product(mul_product)
    );

    wire [7:0] div_quotient, div_remainder;
    non_restoring_div div_unit (
        .clk(clk), .rst(rst),
        .dividend(reg_A_q), .divisor(reg_B_q),
        .c_load(c_d_load),       .c_shift(c_d_shift),
        .c_add(c_d_add),         .c_sub(c_d_sub),
        .c_set_q0(c_d_set_q0),   .c_correct(c_d_correct),
        .c_cnt_load(c_d_cnt_load),.c_cnt_dec(c_d_cnt_dec),
        .s_a_neg(s_a_neg),       .s_cnt_zero(s_d_cnt_zero),
        .s_div_zero(s_div_zero),
        .quotient(div_quotient), .remainder(div_remainder)
    );

    control_unit cu (
        .clk(clk), .rst(rst),
        .start(start), .opcode(opcode),

        .s_q0(s_q0), .s_q_neg1(s_q_neg1), .s_b_cnt_zero(s_b_cnt_zero),

        .s_a_neg(s_a_neg), .s_d_cnt_zero(s_d_cnt_zero), .s_div_zero(s_div_zero),

        .c_load_ops(c_load_ops),

        .c_b_load_M(c_b_load_M), .c_b_load_AQ(c_b_load_AQ),
        .c_b_add(c_b_add), .c_b_sub(c_b_sub),
        .c_b_shift(c_b_shift),
        .c_b_cnt_load(c_b_cnt_load), .c_b_cnt_dec(c_b_cnt_dec),

        .c_d_load(c_d_load), .c_d_shift(c_d_shift),
        .c_d_add(c_d_add), .c_d_sub(c_d_sub),
        .c_d_set_q0(c_d_set_q0), .c_d_correct(c_d_correct),
        .c_d_cnt_load(c_d_cnt_load), .c_d_cnt_dec(c_d_cnt_dec),

        .done(alu_done), .err_div_zero(div_zero)
    );

    reg [15:0] result_r;
    reg        cout_r, ov_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_r <= 16'b0; cout_r <= 1'b0; ov_r <= 1'b0;
        end
        else if (alu_done) begin
            case (opcode)
                2'b00: begin  
                    result_r <= {8'b0, add_result};
                    cout_r   <= add_cout;
                    ov_r     <= add_ov;
                end
                2'b01: begin  
                    result_r <= {8'b0, sub_result};
                    cout_r   <= sub_cout;
                    ov_r     <= sub_ov;
                end
                2'b10: begin  
                    result_r <= mul_product;
                    cout_r   <= 1'b0; ov_r <= 1'b0;
                end
                2'b11: begin
                    result_r <= {div_remainder, div_quotient};
                    cout_r   <= 1'b0; ov_r <= 1'b0;
                end
            endcase
        end
    end

    assign result    = result_r;
    assign carry_out = cout_r;
    assign overflow  = ov_r;

endmodule
