package params

    localparam int VALID_ARRAY_S_INDEX          = 4;
    localparam int VALID_ARRAY_WIDTH            = 1;

    localparam int LRU_ARRAY_S_INDEX            = 4;
    localparam int LRU_ARRAY_WIDTH              = 3;

    localparam int RAT_NUM_REGS                 = 64;
    localparam int RAT_PS_WIDTH                 = $clog2( RAT_NUM_REGS );

    localparam int QUEUE_DATA_WIDTH             = 96;
    localparam int QUEUE_DEPTH                  = 16;

    localparam int FREE_LIST_DATA_WIDTH         = RAT_PS_WIDTH;
    localparam int FREE_LIST_DEPTH              = RAT_NUM_REGS;

    localparam int RENAME_DISPATCH_DATA_WIDTH   = FREE_LIST_DATA_WIDTH;

    localparam int ROB_DATA_WIDTH               = RAT_PS_WIDTH + 5 + 1;
    localparam int ROB_DEPTH                    = 16;

endpackage