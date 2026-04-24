module non_restoring_div (
    input  wire       clk, rst,
    input  wire [7:0] dividend,
    input  wire [7:0] divisor,

    input  wire       c_load,
    input  wire       c_shift,
    input  wire       c_add,
    input  wire       c_sub,
    input  wire       c_set_q0,
    input  wire       c_correct,
    input  wire       c_cnt_load,
    input  wire       c_cnt_dec,

    output wire       s_a_neg,
    output wire       s_cnt_zero,
    output wire       s_div_zero,

    output wire [7:0] quotient,
    output wire [7:0] remainder
);

    wire [7:0] M_q;
    dsr_shift reg_M (
        .clk(clk), .rst(rst),
        .load(c_load), .clr(1'b0),
        .shr(1'b0), .shl(1'b0), .set_lsb(1'b0),
        .d(divisor), .sin_r(1'b0), .sin_l(1'b0), .lsb_val(1'b0),
        .q(M_q), .sout_r(), .sout_l()
    );

    wire [7:0] A_q, Q_q;

    wire [7:0] add_res, sub_res;
    adder_subtractor_8b adder_u (.a(A_q),.b(M_q),.sub(1'b0),.result(add_res),.cout(),.neg());
    adder_subtractor_8b sub_u   (.a(A_q),.b(M_q),.sub(1'b1),.result(sub_res),.cout(),.neg());

    wire       do_add;
    or  g_doa (do_add, c_add, c_correct);          
    wire [7:0] after_add, A_op_res;
    mux_2to1_8b mx_add (.a(A_q),     .b(add_res), .sel(do_add), .y(after_add));
    mux_2to1_8b mx_sub (.a(after_add),.b(sub_res), .sel(c_sub),  .y(A_op_res));

    wire       A_load_en;
    wire [7:0] A_load_val;
    or  g_ale  (A_load_en,  c_load, c_add, c_sub, c_correct);
    mux_2to1_8b mx_az (.a(A_op_res), .b(8'b0), .sel(c_load), .y(A_load_val));

    dsr_shift reg_A (
        .clk(clk), .rst(rst),
        .load(A_load_en), .clr(1'b0),
        .shr(1'b0), .shl(c_shift), .set_lsb(1'b0),
        .d(A_load_val),
        .sin_r(1'b0),
        .sin_l(Q_q[7]),   
        .lsb_val(1'b0),
        .q(A_q), .sout_r(), .sout_l()
    );

    wire q0_bit;
    not g_q0 (q0_bit, A_q[7]);  

    dsr_shift reg_Q (
        .clk(clk), .rst(rst),
        .load(c_load), .clr(1'b0),
        .shr(1'b0), .shl(c_shift), .set_lsb(c_set_q0),
        .d(dividend),
        .sin_r(1'b0), .sin_l(1'b0),
        .lsb_val(q0_bit),   
        .q(Q_q), .sout_r(), .sout_l()
    );

    counter_3b cnt_u (
        .clk(clk), .rst(rst),
        .load(c_cnt_load), .load_val(3'd7),
        .dec(c_cnt_dec),
        .count(), .zero(s_cnt_zero)
    );

    wire dz0, dz1, dz2, dz3;
    nor g_dz0 (dz0, divisor[0], divisor[1]);
    nor g_dz1 (dz1, divisor[2], divisor[3]);
    nor g_dz2 (dz2, divisor[4], divisor[5]);
    nor g_dz3 (dz3, divisor[6], divisor[7]);
    and g_dze (s_div_zero, dz0, dz1, dz2, dz3);

    assign s_a_neg   = A_q[7];
    assign quotient  = Q_q;
    assign remainder = A_q;

endmodule
