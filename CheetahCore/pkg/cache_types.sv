package cache_types;

    typedef struct packed {
        logic   [31:0]  addr;
        logic   [3:0]   rmask;
        logic   [3:0]  wmask;
        logic   [31:0] wdata;

    } shadow_reg_t;

endpackage