// ascu.v - Add-Compare-Select Unit
// Implements the main recursive step of the Viterbi algorithm
// Fixed: Added overflow handling using saturation

module acsu #
(   parameter PM_WIDTH = 8
)(
    // Branch Metric input from BMU
    input [1:0] bm_s0_s0_i,
    input [1:0] bm_s0_s2_i,
    input [1:0] bm_s1_s0_i,
    input [1:0] bm_s1_s2_i,
    input [1:0] bm_s2_s1_i,
    input [1:0] bm_s2_s3_i,
    input [1:0] bm_s3_s1_i,
    input [1:0] bm_s3_s3_i,
    
    // Path Metric input from PMU (previous state)
    input [7:0] pm_s0_i,
    input [7:0] pm_s1_i,
    input [7:0] pm_s2_i,
    input [7:0] pm_s3_i,
    
    // Decision Bit output for PMU
    output [3:0] dec_bits_o,
    
    // New Path Metric output for PMU (with saturation)
    output [7:0] pm_s0_o,
    output [7:0] pm_s1_o,
    output [7:0] pm_s2_o,
    output [7:0] pm_s3_o
);

// Intermediate wires for addition operations
// Use 9 bits to handle potential overflow (8-bit PM + 2-bit BM)
wire [8:0] pm_00, pm_10; // Path costs to S0
wire [8:0] pm_21, pm_31; // Path costs to S1
wire [8:0] pm_02, pm_12; // Path costs to S2
wire [8:0] pm_23, pm_33; // Path costs to S3

// Saturated values (clipped at 255)
wire [7:0] pm_00_sat, pm_10_sat;
wire [7:0] pm_21_sat, pm_31_sat;
wire [7:0] pm_02_sat, pm_12_sat;
wire [7:0] pm_23_sat, pm_33_sat;

// --- 1. ADD Operation ---
// Calculate path costs for all possible transitions
assign pm_00 = {1'b0, pm_s0_i} + {7'b0, bm_s0_s0_i}; 
assign pm_10 = {1'b0, pm_s1_i} + {7'b0, bm_s1_s0_i};

assign pm_21 = {1'b0, pm_s2_i} + {7'b0, bm_s2_s1_i};
assign pm_31 = {1'b0, pm_s3_i} + {7'b0, bm_s3_s1_i};

assign pm_02 = {1'b0, pm_s0_i} + {7'b0, bm_s0_s2_i};
assign pm_12 = {1'b0, pm_s1_i} + {7'b0, bm_s1_s2_i};

assign pm_23 = {1'b0, pm_s2_i} + {7'b0, bm_s2_s3_i};
assign pm_33 = {1'b0, pm_s3_i} + {7'b0, bm_s3_s3_i};

// --- 2. SATURATION Logic ---
// Clip values at 255 to prevent wrap-around
assign pm_00_sat = (pm_00[8]) ? 8'd255 : pm_00[7:0];  // If bit 8 is set (>255), saturate
assign pm_10_sat = (pm_10[8]) ? 8'd255 : pm_10[7:0];
assign pm_21_sat = (pm_21[8]) ? 8'd255 : pm_21[7:0];
assign pm_31_sat = (pm_31[8]) ? 8'd255 : pm_31[7:0];
assign pm_02_sat = (pm_02[8]) ? 8'd255 : pm_02[7:0];
assign pm_12_sat = (pm_12[8]) ? 8'd255 : pm_12[7:0];
assign pm_23_sat = (pm_23[8]) ? 8'd255 : pm_23[7:0];
assign pm_33_sat = (pm_33[8]) ? 8'd255 : pm_33[7:0];

// --- 3. COMPARE & SELECT Operation ---
// Compare saturated values for proper selection
// Decision Bit: 0 if first path is selected, 1 if second path is selected

// Update S0 (From S0 or S1)
assign pm_s0_o  = (pm_00_sat <= pm_10_sat) ? pm_00_sat : pm_10_sat;
assign dec_bits_o[0] = (pm_00_sat <= pm_10_sat) ? 1'b0 : 1'b1; // 0 if from S0, 1 if from S1

// Update S1 (From S2 or S3)
assign pm_s1_o  = (pm_21_sat <= pm_31_sat) ? pm_21_sat : pm_31_sat;
assign dec_bits_o[1] = (pm_21_sat <= pm_31_sat) ? 1'b0 : 1'b1; // 0 if from S2, 1 if from S3

// Update S2 (From S0 or S1)
assign pm_s2_o  = (pm_02_sat <= pm_12_sat) ? pm_02_sat : pm_12_sat;
assign dec_bits_o[2] = (pm_02_sat <= pm_12_sat) ? 1'b0 : 1'b1; // 0 if from S0, 1 if from S1

// Update S3 (From S2 or S3)
assign pm_s3_o  = (pm_23_sat <= pm_33_sat) ? pm_23_sat : pm_33_sat;
assign dec_bits_o[3] = (pm_23_sat <= pm_33_sat) ? 1'b0 : 1'b1; // 0 if from S2, 1 if from S3

// Helper function for debug (not synthesized)
// function [8:0] debug_add;
//     input [7:0] pm;
//     input [1:0] bm;
//     begin
//         debug_add = {1'b0, pm} + {7'b0, bm};
//     end
// endfunction

// Thay đoạn display cũ bằng đoạn này:
always @(pm_s0_i or pm_s1_i) begin
    // Chỉ cần in khi có thay đổi quan trọng hoặc theo Clock (tốt nhất là đưa vào always @(posedge clk) ở top)
    $display("%t | DEBUG_ACSU | PM_In: S0=%d S1=%d S2=%d S3=%d | BM_S0S0=%d BM_S1S0=%d | Dec: %b", 
             $time, pm_s0_i, pm_s1_i, pm_s2_i, pm_s3_i, bm_s0_s0_i, bm_s1_s0_i, dec_bits_o);
end
endmodule