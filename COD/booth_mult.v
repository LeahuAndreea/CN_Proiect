module booth_mult (
    input  wire       clk, rst,
    input  wire [7:0] multiplicand,
    input  wire [7:0] multiplier,

    input  wire       c_load_M,
    input  wire       c_load_AQ,
    input  wire       c_add,
    input  wire       c_sub,
    input  wire       c_shift,
    input  wire       c_cnt_load,
    input  wire       c_cnt_dec,

    output wire       s_q0,
    output wire       s_q_neg1,
    output wire       s_cnt_zero,

    output wire [15:0] product
);

    wire [7:0] M_q;
    dsr_shift reg_M (
        .clk(clk), .rst(rst),
        .load(c_load_M), .clr(1'b0),
        .shr(1'b0), .shl(1'b0), .set_lsb(1'b0),
        .d(multiplicand), .sin_r(1'b0), .sin_l(1'b0), .lsb_val(1'b0),
        .q(M_q), .sout_r(), .sout_l()
    );

    wire [7:0] A_q;

    wire [7:0] add_res, sub_res;
    adder_subtractor_8b adder_u (.a(A_q),.b(M_q),.sub(1'b0),.result(add_res),.cout(),.neg());
    adder_subtractor_8b sub_u   (.a(A_q),.b(M_q),.sub(1'b1),.result(sub_res),.cout(),.neg());

    wire [7:0] after_add, A_op_res;
    mux_2to1_8b mx_add (.a(A_q),     .b(add_res), .sel(c_add), .y(after_add));
    mux_2to1_8b mx_sub (.a(after_add),.b(sub_res), .sel(c_sub), .y(A_op_res));
    wire       A_load_en;
    wire [7:0] A_load_val;
    or  g_ale (A_load_en,  c_load_AQ, c_add, c_sub);
    mux_2to1_8b mx_az (.a(A_op_res), .b(8'b0), .sel(c_load_AQ), .y(A_load_val));

    dsr_shift reg_A (
        .clk(clk), .rst(rst),
        .load(A_load_en), .clr(1'b0),
        .shr(c_shift), .shl(1'b0), .set_lsb(1'b0),
        .d(A_load_val),
        .sin_r(A_q[7]),  
        .sin_l(1'b0), .lsb_val(1'b0),
        .q(A_q), .sout_r(), .sout_l()
    );

    wire [7:0] Q_q;
    dsr_shift reg_Q (
        .clk(clk), .rst(rst),
        .load(c_load_AQ), .clr(1'b0),
        .shr(c_shift), .shl(1'b0), .set_lsb(1'b0),
        .d(multiplier),
        .sin_r(A_q[0]),   
        .sin_l(1'b0), .lsb_val(1'b0),
        .q(Q_q), .sout_r(), .sout_l()
    );

    wire Q1_q;
    wire q1_upd_en, q1_val_src, q1_d;
    or          g_q1en  (q1_upd_en, c_load_AQ, c_shift);
    mux_2to1_1b mx_q1s  (.a(Q_q[0]),  .b(1'b0),    .sel(c_load_AQ), .y(q1_val_src));
    mux_2to1_1b mx_q1f  (.a(Q1_q),    .b(q1_val_src), .sel(q1_upd_en),  .y(q1_d));
    reg_1b      ff_Q1   (.clk(clk), .rst(rst), .d(q1_d), .q(Q1_q));

    counter_3b cnt_u (
        .clk(clk), .rst(rst),
        .load(c_cnt_load), .load_val(3'd7),
        .dec(c_cnt_dec),
        .count(), .zero(s_cnt_zero)
    );

    assign s_q0     = Q_q[0];
    assign s_q_neg1 = Q1_q;
    assign product  = {A_q, Q_q};

endmodule
