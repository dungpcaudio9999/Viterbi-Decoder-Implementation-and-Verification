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
    parameter TBL      = 15,
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
        // Input Chi phí nhánh (từ BMU)
        .bm_s0_s0_i     (w_bm_s0_s0),
        .bm_s0_s2_i     (w_bm_s0_s2),
        .bm_s1_s0_i     (w_bm_s1_s0),
        .bm_s1_s2_i     (w_bm_s1_s2),
        .bm_s2_s1_i     (w_bm_s2_s1),
        .bm_s2_s3_i     (w_bm_s2_s3),
        .bm_s3_s1_i     (w_bm_s3_s1),
        .bm_s3_s3_i     (w_bm_s3_s3),
        
        // Input PM Cũ (từ PMU - Feedback)
        .pm_s0_i        (w_pm_current_s0),
        .pm_s1_i        (w_pm_current_s1),
        .pm_s2_i        (w_pm_current_s2),
        .pm_s3_i        (w_pm_current_s3),
        
        // Output (Decision bits đi thẳng sang TBU)
        .dec_bits_o     (w_dec_bits),
        
        // Output PM Mới (Gửi sang PMU để lưu)
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