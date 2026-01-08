/*
 * MODULE: viterbi_core
 * CHỨC NĂNG: Chứa 4 khối lõi (BMU, ACSU, PMU, TBU)
 * KIẾN TRÚC: Pipeline hoàn toàn (Register Exchange)
 * TỐC ĐỘ: 1 bit input -> 1 bit output (sau độ trễ TBL)
 */
 `include "piso.v"
 `include "bmu.v"
 `include "acsu.v"
 `include "pmu.v"
 `include "tbu.v"
 `include "sipo.v"
 
module viterbi_core #(
    parameter TBL      = 32,
    parameter PM_WIDTH = 8
)(
    input  wire           clk,
    input  wire           rst_n,
    input  wire           valid_i,        // valid_serial_o từ PISO
    input  wire [1:0]     data_core_i,    // data_serial_o từ PISO
    
    output wire           data_serial_o,  // Gửi cho SIPO
    output wire           valid_serial_o, // Gửi cho SIPO
    output wire           busy_o          // Luôn bằng 0 trong kiến trúc mới
);
    // =================================================================
    // 1. DÂY NỐI NỘI BỘ (Kết nối 4 khối)
    // =================================================================

    // --- BMU -> ACSU (8 giá trị chi phí nhánh) ---
    wire [1:0] w_bm_s0_s0;
    wire [1:0] w_bm_s0_s2;
    wire [1:0] w_bm_s1_s0;
    wire [1:0] w_bm_s1_s2;
    wire [1:0] w_bm_s2_s1;
    wire [1:0] w_bm_s2_s3;
    wire [1:0] w_bm_s3_s1;
    wire [1:0] w_bm_s3_s3;

    // --- ACSU -> TBU & PMU ---
    wire [3:0] w_dec_bits;          // Bit quyết định: Nối THẲNG sang TBU
    
    // --- ACSU -> PMU (Path Metric mới cần lưu và chuẩn hóa) ---
    wire [PM_WIDTH-1:0] w_pm_new_s0;
    wire [PM_WIDTH-1:0] w_pm_new_s1;
    wire [PM_WIDTH-1:0] w_pm_new_s2;
    wire [PM_WIDTH-1:0] w_pm_new_s3;

    // --- PMU -> ACSU & TBU (Path Metric hiện tại) ---
    // Nối về ACSU: Để tính tiếp bước sau (Feedback loop)
    // Nối sang TBU: Để chọn đường đi có metric nhỏ nhất làm kết quả
    wire [PM_WIDTH-1:0] w_pm_current_s0;
    wire [PM_WIDTH-1:0] w_pm_current_s1;
    wire [PM_WIDTH-1:0] w_pm_current_s2;
    wire [PM_WIDTH-1:0] w_pm_current_s3;

    // =================================================================
    // 2. KẾT NỐI (INSTANTIATION) 4 KHỐI LÕI
    // =================================================================

    // --- KHỐI 1: BMU (Tính khoảng cách Hamming) ---
    bmu bmu_inst (
        .piso_data_i    (data_core_i),
        .bm_s0_s0_o     (w_bm_s0_s0),
        .bm_s0_s2_o     (w_bm_s0_s2),
        .bm_s1_s0_o     (w_bm_s1_s0),
        .bm_s1_s2_o     (w_bm_s1_s2),
        .bm_s2_s1_o     (w_bm_s2_s1),
        .bm_s2_s3_o     (w_bm_s2_s3),
        .bm_s3_s1_o     (w_bm_s3_s1),
        .bm_s3_s3_o     (w_bm_s3_s3)
    );

    // --- KHỐI 2: ACSU (Cộng - So sánh - Chọn) ---
    acsu #(
        .PM_WIDTH       (PM_WIDTH)
    ) acsu_inst (
        // --- BRANCH METRICS MAPPING (QUAN TRỌNG) ---
        // Sơ đồ Shift Left (Poly 111, 101):
        // S0 -> S0 (Out 00), S0 -> S1 (Out 11)
        // S1 -> S2 (Out 10), S1 -> S3 (Out 01)
        // S2 -> S0 (Out 11), S2 -> S1 (Out 00)
        // S3 -> S2 (Out 01), S3 -> S3 (Out 10)

        // Cổng của ACSU (Shift Left) -> Nối với dây BMU tương ứng
        
        // 1. Nhóm tính S0 (Đến từ S0, S2)
        .bm_s0_s0_i     (w_bm_s0_s0), // S0->S0 (Out 00) -> Đúng
        .bm_s2_s3_i     (w_bm_s0_s2), // S2->S0 (Out 11) -> Nối vào dây w_bm_s0_s2 (vì w_bm_s0_s2 là khoảng cách với '11')
                                      // Lưu ý: Tên dây w_bm_s0_s2 trong BMU thường ám chỉ BM với 11.
                                      // Trong ACSU mới, cổng này tên là bm_s2_s3_i (do đệ mượn cổng).

        // 2. Nhóm tính S1 (Đến từ S0, S2)
        .bm_s0_s2_i     (w_bm_s0_s2), // S0->S1 (Out 11) -> Dùng w_bm_s0_s2
        .bm_s2_s1_i     (w_bm_s0_s0), // S2->S1 (Out 00) -> Dùng w_bm_s0_s0 (Khoảng cách với 00)

        // 3. Nhóm tính S2 (Đến từ S1, S3)
        .bm_s1_s2_i     (w_bm_s1_s2), // S1->S2 (Out 10) -> Đúng
        .bm_s3_s1_i     (w_bm_s2_s3), // S3->S2 (Out 01) -> Dùng w_bm_s2_s3 (Khoảng cách với 01)

        // 4. Nhóm tính S3 (Đến từ S1, S3)
        .bm_s1_s0_i     (w_bm_s2_s3), // S1->S3 (Out 01) -> Dùng w_bm_s2_s3
        .bm_s3_s3_i     (w_bm_s1_s2), // S3->S3 (Out 10) -> Dùng w_bm_s1_s2

        // --- CÁC CỔNG CÒN LẠI GIỮ NGUYÊN ---
        .pm_s0_i        (w_pm_current_s0),
        .pm_s1_i        (w_pm_current_s1),
        .pm_s2_i        (w_pm_current_s2),
        .pm_s3_i        (w_pm_current_s3),
        
        .dec_bits_o     (w_dec_bits),
        
        .pm_s0_o        (w_pm_new_s0),
        .pm_s1_o        (w_pm_new_s1),
        .pm_s2_o        (w_pm_new_s2),
        .pm_s3_o        (w_pm_new_s3)
    );

    // --- KHỐI 3: PMU (Lưu trữ & Chuẩn hóa Metric) ---
    // Khối này giờ nhẹ hơn nhiều, không còn lưu lịch sử bit
    pmu #(
        .TBL            (TBL),
        .PM_WIDTH       (PM_WIDTH)
    ) pmu_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_i        (valid_i),
        
        // Input PM Mới (từ ACSU)
        .pm_new_s0_i    (w_pm_new_s0),
        .pm_new_s1_i    (w_pm_new_s1),
        .pm_new_s2_i    (w_pm_new_s2),
        .pm_new_s3_i    (w_pm_new_s3),
        
        // Output PM Hiện tại (đã chuẩn hóa)
        .pm_current_s0_o(w_pm_current_s0),
        .pm_current_s1_o(w_pm_current_s1),
        .pm_current_s2_o(w_pm_current_s2),
        .pm_current_s3_o(w_pm_current_s3)
    );

    // --- KHỐI 4: TBU (Register Exchange Pipeline) ---
    // Khối này giờ nhận trực tiếp bit từ ACSU và đẩy dữ liệu ra liên tục
    tbu #(
        .TBL            (TBL),
        .PM_WIDTH       (PM_WIDTH)
    ) tbu_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_i        (valid_i),
        .busy_o         (busy_o), // Luôn = 0
        
        // Input Bit quyết định (Trực tiếp từ ACSU)
        .dec_bits_i     (w_dec_bits),
        
        // Input PM Hiện tại (Từ PMU - để chọn kết quả tốt nhất)
        .pm_s0_i        (w_pm_new_s0),
        .pm_s1_i        (w_pm_new_s1),
        .pm_s2_i        (w_pm_new_s2),
        .pm_s3_i        (w_pm_new_s3),
        
        // Output Kết quả giải mã
        .data_serial_o  (data_serial_o),
        .valid_serial_o (valid_serial_o)
    );

endmodule