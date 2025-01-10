module DW02_mult_3_stage_inst #(parameter int A_WIDTH = 32,
                                parameter int B_WIDTH = 32)
(
    input   logic   [32 : 0] inst_A,
    input   logic   [32 : 0] inst_B,
    input   logic   inst_TC,
    input   logic   inst_CLK,
    // output  logic   [65:0]  PRODUCT_inst_64,
    output  logic   [65:0]                  PRODUCT_inst_66
);

            // Instance of DW02_mult_3_stage
            logic [65:0] full_product_66_mulhsu;
            logic [65:0] full_product_66;


   
    

    // DW02_mult_3_stage #( 33, 33 ) U1 (
    //     .A                  ( inst_A ),
    //     .B                  ( inst_B ),
    //     .TC                 ( inst_TC ),
    //     .CLK                ( inst_CLK ),
    //     .PRODUCT            ( full_product_66_mulhsu )
    // );

    DW02_mult_3_stage #( 33, 33 ) U2 (
        .A                  ( inst_A ),
        .B                  ( inst_B ),
        .TC                 ( inst_TC ),
        .CLK                ( inst_CLK ),
        .PRODUCT            ( full_product_66 )
    );

    // assign PRODUCT_inst = mulhsu_flag ? ( full_product_66[63:0] ) : full_product_64;
    // assign PRODUCT_inst_64 = full_product_66_mulhsu;
    assign PRODUCT_inst_66 = full_product_66;

endmodule
