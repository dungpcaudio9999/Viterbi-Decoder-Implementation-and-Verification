// bmu.v - Branch Metric Unit
// Computes Hamming Distance (Branch Metric)
module bmu (
    input  [1:0] piso_data_i,    // Received data (2 bits)
    
    // Output Hamming Distance (2 bits)
    output [1:0] bm_s0_s0_o,
    output [1:0] bm_s0_s2_o,
    output [1:0] bm_s1_s0_o,
    output [1:0] bm_s1_s2_o,
    output [1:0] bm_s2_s1_o,
    output [1:0] bm_s2_s3_o,
    output [1:0] bm_s3_s1_o,
    output [1:0] bm_s3_s3_o
);

// --- Expected Codeword Declarations ---
parameter C00 = 2'b00; // Expected Codeword for S0 -> S0
parameter C02 = 2'b11; // Expected Codeword for S0 -> S2
parameter C10 = 2'b11; // Expected Codeword for S1 -> S0
parameter C12 = 2'b00; // Expected Codeword for S1 -> S2
parameter C21 = 2'b10; // Expected Codeword for S2 -> S1
parameter C23 = 2'b01; // Expected Codeword for S2 -> S3
parameter C31 = 2'b01; // Expected Codeword for S3 -> S1
parameter C33 = 2'b10; // Expected Codeword for S3 -> S3

// --- Intermediate wire Declarations   tions for XOR results (Hamming Distance) ---
// Each wire has 2-bit width
wire [1:0] diff_s0_s0 = piso_data_i ^ C00;
wire [1:0] diff_s0_s2 = piso_data_i ^ C02;
wire [1:0] diff_s1_s0 = piso_data_i ^ C10;
wire [1:0] diff_s1_s2 = piso_data_i ^ C12;
wire [1:0] diff_s2_s1 = piso_data_i ^ C21;
wire [1:0] diff_s2_s3 = piso_data_i ^ C23;
wire [1:0] diff_s3_s1 = piso_data_i ^ C31;
wire [1:0] diff_s3_s3 = piso_data_i ^ C33;

// --- Hamming Distance Calculation Function ---
// Uses single-bit addition with intermediate variables for easier compiler handling.

assign bm_s0_s0_o = diff_s0_s0[1] + diff_s0_s0[0];
assign bm_s0_s2_o = diff_s0_s2[1] + diff_s0_s2[0];

assign bm_s1_s0_o = diff_s1_s0[1] + diff_s1_s0[0];
assign bm_s1_s2_o = diff_s1_s2[1] + diff_s1_s2[0];

assign bm_s2_s1_o = diff_s2_s1[1] + diff_s2_s1[0];
assign bm_s2_s3_o = diff_s2_s3[1] + diff_s2_s3[0];

assign bm_s3_s1_o = diff_s3_s1[1] + diff_s3_s1[0];
assign bm_s3_s3_o = diff_s3_s3[1] + diff_s3_s3[0];

// Thêm vào cuối file bmu.v
always @(piso_data_i) begin
    $display("%-10t | [DEBUG_BMU] Input: %b | BM_S0_S0: %d, BM_S0_S2: %d", 
             $time, piso_data_i, bm_s0_s0_o, bm_s0_s2_o);
end

endmodule

