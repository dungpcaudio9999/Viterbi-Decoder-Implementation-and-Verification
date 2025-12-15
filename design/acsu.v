// ascu.v - Add-Compare-Select Unit
// Th?c hi?n b??c ?? quy chính c?a thu?t toán Viterbi

module acsu #
( parameter PM_WIDTH = 8
)(
    // ??u vào Chi phí Nhánh (Branch Metric) t? BMU
    input [1:0] bm_s0_s0_i,
    input [1:0] bm_s0_s2_i,
    input [1:0] bm_s1_s0_i,
    input [1:0] bm_s1_s2_i,
    input [1:0] bm_s2_s1_i,
    input [1:0] bm_s2_s3_i,
    input [1:0] bm_s3_s1_i,
    input [1:0] bm_s3_s3_i,
    
    // ??u vào T?ng Chi phí (Path Metric) c? t? PMU
    input [7:0] pm_s0_i,
    input [7:0] pm_s1_i,
    input [7:0] pm_s2_i,
    input [7:0] pm_s3_i,
    
    // ??u ra Bit Quy?t ??nh (Decision Bit) cho PMU
    output [3:0] dec_bits_o,
    
    // ??u ra T?ng Chi phí (Path Metric) M?I cho PMU
    output [7:0] pm_s0_o,
    output [7:0] pm_s1_o,
    output [7:0] pm_s2_o,
    output [7:0] pm_s3_o
);

// Khai báo dây (wire) trung gian cho các phép c?ng (Add)
// K?t qu? c?ng (BM + PM c?) có th? lên t?i 8 bit + 2 bit, nên dùng 9 bit ?? an toàn
wire [8:0] pm_00, pm_10; // Chi phí ???ng ??n S0
wire [8:0] pm_21, pm_31; // Chi phí ???ng ??n S1
wire [8:0] pm_02, pm_12; // Chi phí ???ng ??n S2
wire [8:0] pm_23, pm_33; // Chi phí ???ng ??n S3

// --- 1. Phép C?ng (ADD) ---
// Tính Chi phí ???ng d?n cho t?t c? các chuy?n ??i có th? có
// L?u ý: M? r?ng bm_..._i t? 2 bit lên 9 bit b?ng 0 ?? phép c?ng chính xác
assign pm_00 = {7'b0, bm_s0_s0_i} + pm_s0_i; 
assign pm_10 = {7'b0, bm_s1_s0_i} + pm_s1_i;

assign pm_21 = {7'b0, bm_s2_s1_i} + pm_s2_i;
assign pm_31 = {7'b0, bm_s3_s1_i} + pm_s3_i;

assign pm_02 = {7'b0, bm_s0_s2_i} + pm_s0_i;
assign pm_12 = {7'b0, bm_s1_s2_i} + pm_s1_i;

assign pm_23 = {7'b0, bm_s2_s3_i} + pm_s2_i;
assign pm_33 = {7'b0, bm_s3_s3_i} + pm_s3_i;


// --- 2. Phép So sánh và Ch?n (COMPARE & SELECT) ---
// ??ng th?i xác ??nh PM m?i và Bit Quy?t ??nh (Decision Bit)
// Bit Quy?t ??nh: 0 n?u PM_A ???c ch?n, 1 n?u PM_B ???c ch?n (quy ??c có th? tùy ch?nh)

// C?p nh?t S0 (T? S0 ho?c S1)
assign pm_s0_o  = (pm_00 <= pm_10) ? pm_00[7:0] : pm_10[7:0];
assign dec_bits_o[0] = (pm_00 <= pm_10) ? 1'b0 : 1'b1; // 0 n?u ch?n t? S0, 1 n?u ch?n t? S1

// C?p nh?t S1 (T? S2 ho?c S3)
assign pm_s1_o  = (pm_21 <= pm_31) ? pm_21[7:0] : pm_31[7:0];
assign dec_bits_o[1] = (pm_21 <= pm_31) ? 1'b0 : 1'b1; // 0 n?u ch?n t? S2, 1 n?u ch?n t? S3

// C?p nh?t S2 (T? S0 ho?c S1)
assign pm_s2_o  = (pm_02 <= pm_12) ? pm_02[7:0] : pm_12[7:0];
assign dec_bits_o[2] = (pm_02 <= pm_12) ? 1'b0 : 1'b1; // 0 n?u ch?n t? S0, 1 n?u ch?n t? S1

// C?p nh?t S3 (T? S2 ho?c S3)
assign pm_s3_o  = (pm_23 <= pm_33) ? pm_23[7:0] : pm_33[7:0];
assign dec_bits_o[3] = (pm_23 <= pm_33) ? 1'b0 : 1'b1; // 0 n?u ch?n t? S2, 1 n?u ch?n t? S3

endmodule
