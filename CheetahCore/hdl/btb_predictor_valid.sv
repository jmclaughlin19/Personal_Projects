module btb_predictor_valid_array #(
    parameter S_INDEX = 8,      // Number of address bits (log2(NUM_SETS))
    parameter WIDTH   = 1       // Width of the valid array entries
)(
    input  logic                clk,    // Clock
    input  logic                rst,    // Reset (active high)
    input  logic                csb,    // Chip select (active low)
    input  logic                web,    // Write enable (active low)
    input  logic [S_INDEX-1:0]  waddr,  // Write address
    input  logic [WIDTH-1:0]    din,    // Write data
    input  logic [S_INDEX-1:0]  raddr,  // Read address

    output logic [WIDTH-1:0]    dout    // Read data
);

    localparam NUM_SETS = 2**S_INDEX;   // Number of entries in the array

    // Internal storage array
    logic [WIDTH-1:0] internal_array [NUM_SETS];

    // Sequential write process
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                internal_array[i] <= '0;
            end
        end else if (!csb && !web) begin
            internal_array[waddr] <= din; // Write data to specified address
        end
    end

    // Sequential read process
    logic [WIDTH-1:0] read_data;
    always_ff @(posedge clk) begin
        if (!csb) begin
            read_data <= internal_array[raddr]; // Read data from specified address
        end
    end

    assign dout = read_data;

endmodule
