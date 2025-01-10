// module DW_div_seq_inst_unsigned #(
//     parameter int inst_a_width = 32,
//     parameter int inst_b_width = 32,
//     parameter int inst_tc_mode = 0,
//     parameter int inst_num_cyc = 8,
//     parameter int inst_rst_mode = 1,
//     parameter int inst_input_mode = 1,
//     parameter int inst_output_mode = 0,
//     parameter int inst_early_start = 0
// ) (
//     input  logic                      inst_clk,
//     input  logic                      inst_rst_n,
//     input  logic                      inst_hold,
//     input  logic                      inst_start,
//     input  logic [inst_a_width-1:0]   inst_a,
//     input  logic [inst_b_width-1:0]   inst_b,
//     output logic                      complete_inst,
//     output logic                      divide_by_0_inst,
//     output logic [inst_a_width-1:0]   quotient_inst,
//     output logic [inst_b_width-1:0]   remainder_inst
// );

//     // // Instance of DW_div_seq
//     // DW_div_seq #(
//     //     .a_width(inst_a_width),
//     //     .b_width(inst_b_width),
//     //     .tc_mode(inst_tc_mode),
//     //     .num_cyc(inst_num_cyc),
//     //     .rst_mode(inst_rst_mode),
//     //     .input_mode(inst_input_mode),
//     //     .output_mode(inst_output_mode),
//     //     .early_start(inst_early_start)
//     // ) U3 (
//     //     .clk(inst_clk),
//     //     .rst_n(inst_rst_n),
//     //     .hold(inst_hold),
//     //     .start(inst_start),
//     //     .a(inst_a),
//     //     .b(inst_b),
//     //     .complete(complete_inst),
//     //     .divide_by_0(divide_by_0_inst),
//     //     .quotient(quotient_inst),
//     //     .remainder(remainder_inst)
//     // );

// endmodule

// #################################################################################################################


module DW_div_seq_inst_signed #(
    parameter int inst_a_width = 33,
    parameter int inst_b_width = 33,
    parameter int inst_tc_mode = 1,
    parameter int inst_num_cyc = 9,
    parameter int inst_rst_mode = 1,
    parameter int inst_input_mode = 1,
    parameter int inst_output_mode = 0,
    parameter int inst_early_start = 0
) (
    input  logic                      inst_clk,
    input  logic                      inst_rst_n,
    input  logic                      inst_hold,
    input  logic                      inst_start,
    input  logic [inst_a_width-1:0]   inst_a,
    input  logic [inst_b_width-1:0]   inst_b,
    output logic                      complete_inst,
    output logic                      divide_by_0_inst,
    output logic [inst_a_width-1:0]   quotient_inst,
    output logic [inst_b_width-1:0]   remainder_inst
);

    // Instance of DW_div_seq
    DW_div_seq #(
        .a_width(inst_a_width),
        .b_width(inst_b_width),
        .tc_mode(inst_tc_mode),
        .num_cyc(inst_num_cyc),
        .rst_mode(inst_rst_mode),
        .input_mode(inst_input_mode),
        .output_mode(inst_output_mode),
        .early_start(inst_early_start)
    ) U4 (
        .clk(inst_clk),
        .rst_n(inst_rst_n),
        .hold(inst_hold),
        .start(inst_start),
        .a(inst_a),
        .b(inst_b),
        .complete(complete_inst),
        .divide_by_0(divide_by_0_inst),
        .quotient(quotient_inst),
        .remainder(remainder_inst)
    );

endmodule
