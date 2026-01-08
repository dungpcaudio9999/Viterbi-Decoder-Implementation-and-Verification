// acsu.v - Add-Compare-Select Unit (CORRECTED FOR SHIFT LEFT TOPOLOGY)
// Topology: 
// S0 & S1 <- Source S0 & S2
// S2 & S3 <- Source S1 & S3

module acsu #
(   parameter PM_WIDTH = 8
)(
    // Branch Metrics (Khoảng cách Hamming)
    // Đại ca chú ý: Các input này nên nối với Distance của (00, 01, 10, 11) từ BMU
    // Ở đây đệ giữ nguyên tên port để Đại ca đỡ phải sửa system_top, 
    // nhưng hãy đảm bảo nối đúng ý nghĩa (xem comment ở dưới).
    input [1:0] bm_s0_s0_i, // BM cho nhánh Output 00
    input [1:0] bm_s0_s2_i, // BM cho nhánh Output 11 (hoặc tương đương)
    input [1:0] bm_s1_s0_i, 
    input [1:0] bm_s1_s2_i, 
    input [1:0] bm_s2_s1_i, 
    input [1:0] bm_s2_s3_i, 
    input [1:0] bm_s3_s1_i, 
    input [1:0] bm_s3_s3_i, 
    
    // Path Metric cũ (Previous State)
    input [7:0] pm_s0_i,
    input [7:0] pm_s1_i,
    input [7:0] pm_s2_i,
    input [7:0] pm_s3_i,
    
    // Output
    output [3:0] dec_bits_o,
    output [7:0] pm_s0_o,
    output [7:0] pm_s1_o,
    output [7:0] pm_s2_o,
    output [7:0] pm_s3_o
);

    // Dây trung gian (9 bit để tránh tràn khi cộng)
    wire [8:0] sum_s0_src0, sum_s0_src2; // Đích S0 (Nguồn S0, S2)
    wire [8:0] sum_s1_src0, sum_s1_src2; // Đích S1 (Nguồn S0, S2)
    wire [8:0] sum_s2_src1, sum_s2_src3; // Đích S2 (Nguồn S1, S3)
    wire [8:0] sum_s3_src1, sum_s3_src3; // Đích S3 (Nguồn S1, S3)

    // Giá trị bão hòa (Saturation)
    wire [7:0] pm_s0_cand0, pm_s0_cand2;
    wire [7:0] pm_s1_cand0, pm_s1_cand2;
    wire [7:0] pm_s2_cand1, pm_s2_cand3;
    wire [7:0] pm_s3_cand1, pm_s3_cand3;

    // --- 1. ADD OPERATION (RE-WIRED FOR SHIFT LEFT) ---
    // Encoder: {reg[1:0], in} -> Poly (111, 101) -> Out {X,Y}
    
    // -> Đích S0 (00): Từ S0(00) + in(0)->Out(00) | Từ S2(10) + in(0)->Out(11)
    assign sum_s0_src0 = {1'b0, pm_s0_i} + {7'b0, bm_s0_s0_i}; // Từ S0
    assign sum_s0_src2 = {1'b0, pm_s2_i} + {7'b0, bm_s2_s3_i}; // Từ S2 (Mượn cổng bm_s2_s3, đảm bảo đây là BM của 11)

    // -> Đích S1 (01): Từ S0(00) + in(1)->Out(11) | Từ S2(10) + in(1)->Out(00)
    assign sum_s1_src0 = {1'b0, pm_s0_i} + {7'b0, bm_s0_s2_i}; // Từ S0 (Mượn cổng bm_s0_s2, BM của 11)
    assign sum_s1_src2 = {1'b0, pm_s2_i} + {7'b0, bm_s2_s1_i}; // Từ S2 (Mượn cổng bm_s2_s1, BM của 00)

    // -> Đích S2 (10): Từ S1(01) + in(0)->Out(10) | Từ S3(11) + in(0)->Out(01)
    assign sum_s2_src1 = {1'b0, pm_s1_i} + {7'b0, bm_s1_s2_i}; // Từ S1 (BM của 10)
    assign sum_s2_src3 = {1'b0, pm_s3_i} + {7'b0, bm_s3_s1_i}; // Từ S3 (BM của 01)

    // -> Đích S3 (11): Từ S1(01) + in(1)->Out(01) | Từ S3(11) + in(1)->Out(10)
    assign sum_s3_src1 = {1'b0, pm_s1_i} + {7'b0, bm_s1_s0_i}; // Từ S1 (BM của 01 - Mượn cổng)
    assign sum_s3_src3 = {1'b0, pm_s3_i} + {7'b0, bm_s3_s3_i}; // Từ S3 (BM của 10)

    // --- 2. SATURATION LOGIC (Giữ nguyên) ---
    assign pm_s0_cand0 = (sum_s0_src0[8]) ? 8'd255 : sum_s0_src0[7:0];
    assign pm_s0_cand2 = (sum_s0_src2[8]) ? 8'd255 : sum_s0_src2[7:0];
    
    assign pm_s1_cand0 = (sum_s1_src0[8]) ? 8'd255 : sum_s1_src0[7:0];
    assign pm_s1_cand2 = (sum_s1_src2[8]) ? 8'd255 : sum_s1_src2[7:0];
    
    assign pm_s2_cand1 = (sum_s2_src1[8]) ? 8'd255 : sum_s2_src1[7:0];
    assign pm_s2_cand3 = (sum_s2_src3[8]) ? 8'd255 : sum_s2_src3[7:0];
    
    assign pm_s3_cand1 = (sum_s3_src1[8]) ? 8'd255 : sum_s3_src1[7:0];
    assign pm_s3_cand3 = (sum_s3_src3[8]) ? 8'd255 : sum_s3_src3[7:0];

    // --- 3. COMPARE & SELECT ---
    // Decision Bit = 0: Chọn nhánh TRÊN (S0 hoặc S1)
    // Decision Bit = 1: Chọn nhánh DƯỚI (S2 hoặc S3)

    // Update S0 (Nguồn S0 vs S2)
    assign pm_s0_o      = (pm_s0_cand0 <= pm_s0_cand2) ? pm_s0_cand0 : pm_s0_cand2;
    assign dec_bits_o[0]= (pm_s0_cand0 <= pm_s0_cand2) ? 1'b0 : 1'b1;

    // Update S1 (Nguồn S0 vs S2)
    assign pm_s1_o      = (pm_s1_cand0 <= pm_s1_cand2) ? pm_s1_cand0 : pm_s1_cand2;
    assign dec_bits_o[1]= (pm_s1_cand0 <= pm_s1_cand2) ? 1'b0 : 1'b1;

    // Update S2 (Nguồn S1 vs S3)
    assign pm_s2_o      = (pm_s2_cand1 <= pm_s2_cand3) ? pm_s2_cand1 : pm_s2_cand3;
    assign dec_bits_o[2]= (pm_s2_cand1 <= pm_s2_cand3) ? 1'b0 : 1'b1;

    // Update S3 (Nguồn S1 vs S3)
    assign pm_s3_o      = (pm_s3_cand1 <= pm_s3_cand3) ? pm_s3_cand1 : pm_s3_cand3;
    assign dec_bits_o[3]= (pm_s3_cand1 <= pm_s3_cand3) ? 1'b0 : 1'b1;

    // --- DEBUG ---
    `ifdef DEBUG_TRACE
        always @(pm_s0_i or pm_s1_i or pm_s2_i or pm_s3_i) begin
            $display("[TIME %0t][ACSU] PM_In: S0=%d S1=%d S2=%d S3=%d | Dec: %b", 
                     $time, pm_s0_i, pm_s1_i, pm_s2_i, pm_s3_i, dec_bits_o);
        end
    `endif

endmodule