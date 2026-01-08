// bmu.v - Branch Metric Unit (CORRECTED FOR SHIFT LEFT ENCODER)
// Encoder: Shift Left. Poly: X=111, Y=101. Output: {X, Y}

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

// --- CẬP NHẬT BẢNG MÃ CHUẨN (SHIFT LEFT) ---
// S0(00) + 0 -> S0(00): Out 00
// S0(00) + 1 -> S1(01): Out 11
// S1(01) + 0 -> S2(10): Out 10
// S1(01) + 1 -> S3(11): Out 01
// S2(10) + 0 -> S0(00): Out 11
// S2(10) + 1 -> S1(01): Out 00
// S3(11) + 0 -> S2(10): Out 01
// S3(11) + 1 -> S3(11): Out 10

parameter C00 = 2'b00; // S0 -> S0
parameter C01 = 2'b11; // S0 -> S1 (Cổng cũ tên s0_s2, nhưng dùng cho nhánh 11) -> OK
parameter C12 = 2'b10; // S1 -> S2 (SỬA LẠI TỪ 00 THÀNH 10) <--- QUAN TRỌNG NHẤT
parameter C13 = 2'b01; // S1 -> S3 (Cổng cũ tên s2_s3, dùng cho nhánh 01) -> OK

parameter C20 = 2'b11; // S2 -> S0
parameter C21 = 2'b00; // S2 -> S1
parameter C32 = 2'b01; // S3 -> S2
parameter C33 = 2'b10; // S3 -> S3

// --- TÍNH TOÁN KHOẢNG CÁCH (XOR) ---
// Lưu ý: Các dây output vẫn giữ tên cũ để tương thích với system_top
// Nhưng giá trị so sánh (Parameter) đã được sửa đúng.

// Nhánh Output 00 (Dùng C00)
wire [1:0] diff_s0_s0 = piso_data_i ^ C00; 
assign bm_s0_s0_o = diff_s0_s0[1] + diff_s0_s0[0];

// Nhánh Output 11 (Dùng C01/C20 - Cũ là C02)
wire [1:0] diff_s0_s2 = piso_data_i ^ C01; 
assign bm_s0_s2_o = diff_s0_s2[1] + diff_s0_s2[0];

// Nhánh Output 10 (Dùng C12/C33) <--- SỬA CHỖ NÀY
wire [1:0] diff_s1_s2 = piso_data_i ^ C12; // So sánh với 10
assign bm_s1_s2_o = diff_s1_s2[1] + diff_s1_s2[0];

// Nhánh Output 01 (Dùng C13/C32 - Cũ là C23)
wire [1:0] diff_s2_s3 = piso_data_i ^ C13; 
assign bm_s2_s3_o = diff_s2_s3[1] + diff_s2_s3[0];

// --- CÁC DÂY THỪA (KHÔNG DÙNG TRONG MAP MỚI NHƯNG GIỮ ĐỂ KHÔNG BÁO LỖI) ---
assign bm_s1_s0_o = 0; 
assign bm_s2_s1_o = 0; 
assign bm_s3_s1_o = 0; 
assign bm_s3_s3_o = 0;

`ifdef DEBUG_TRACE
    always @(piso_data_i) begin
        $display("[TIME %0t][BMU] Input Symbol: %b | BM(00)=%d, BM(11)=%d, BM(10)=%d, BM(01)=%d", 
                 $time, piso_data_i, bm_s0_s0_o, bm_s0_s2_o, bm_s1_s2_o, bm_s2_s3_o); 
    end
`endif

endmodule