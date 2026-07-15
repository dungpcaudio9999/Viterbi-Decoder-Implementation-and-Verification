`include "sync_fifo.v"
`include "piso.v"
`include "sipo.v"
`include "viterbi_core.v"

module system_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        dvalid_i,     // Input Valid (Write Enable for FIFO)
    input  wire [15:0] data_i,       // Input Data
    output wire [7:0]  data_o,       // Output Data
    output wire        valid_o,      // Output Valid
    output wire        busy_o        // Busy signal (When FIFO is full)
);

    // --- FIFO to PISO connection wires ---
    wire        fifo_full;
    wire        fifo_empty;
    wire        piso_rd_en;
    wire [15:0] fifo_data_out;

    // --- PISO to Core connection wires ---
    wire [1:0]  piso_to_core_data;
    wire        piso_to_core_valid;

    // --- Core to SIPO connection wires ---
    wire        core_to_sipo_data;
    wire        core_to_sipo_valid;

    // --- 1. FIFO Input Buffer ---
    // Input buffer to prevent data loss when PISO is busy
    sync_fifo #(
        .DATA_WIDTH(16),
        .DEPTH(16)      // Can hold 16 packets (16 * 16 bits)
    ) u_input_fifo (
        .clk(clk),
        .rst_n(rst_n),
        // Write side (From outside)
        .wr_en_i(dvalid_i),
        .wr_data_i(data_i),
        .full_o(fifo_full),
        // Read side (To PISO)
        .rd_en_i(piso_rd_en),
        .rd_data_o(fifo_data_out),
        .empty_o(fifo_empty)
    );

    // --- 2. PISO (Active Mode) ---
    piso u_piso (
        .clk(clk),
        .rst_n(rst_n),
        // Get data from FIFO
        .fifo_data_i(fifo_data_out),
        .fifo_empty_i(fifo_empty),
        .fifo_rd_en_o(piso_rd_en),
        // Push to Core
        .data_serial_o(piso_to_core_data),
        .valid_serial_o(piso_to_core_valid)
    );

    // --- 3. Viterbi Core (Latest Pipeline/PMU_RE version) ---
    // (Remember to use the viterbi_core.v file written in the previous step)
    viterbi_core u_viterbi_core (
        .clk(clk),
        .rst_n(rst_n),
        .piso_data_i(piso_to_core_data),
        .valid_i(piso_to_core_valid),
        .core_data_o(core_to_sipo_data),
        .core_valid_o(core_to_sipo_valid)
    );

    // --- 4. SIPO ---
    sipo u_sipo (
        .clk(clk),
        .rst_n(rst_n),
        .data_serial_i(core_to_sipo_data),
        .valid_serial_i(core_to_sipo_valid),
        .data_parallel_o(data_o),
        .byte_ready_o(valid_o)
    );

    // Busy Logic:
    // Now the system is only truly "busy" (rejects input) when the FIFO is full.
    // If FIFO is not full, external sources can still send data in.
    assign busy_o = fifo_full;

endmodule
