module pmu #(
    parameter TBL      = 15,
    parameter PM_WIDTH = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,

    // Input từ ACSU (Metric mới chưa chuẩn hóa)
    input  wire [PM_WIDTH-1:0] pm_new_s0_i,
    input  wire [PM_WIDTH-1:0] pm_new_s1_i,
    input  wire [PM_WIDTH-1:0] pm_new_s2_i,
    input  wire [PM_WIDTH-1:0] pm_new_s3_i,

    // Output về ACSU và TBU (Metric đã lưu và chuẩn hóa)
    output reg  [PM_WIDTH-1:0] pm_current_s0_o,
    output reg  [PM_WIDTH-1:0] pm_current_s1_o,
    output reg  [PM_WIDTH-1:0] pm_current_s2_o,
    output reg  [PM_WIDTH-1:0] pm_current_s3_o
);

    // Tìm giá trị nhỏ nhất để chuẩn hóa (Tránh tràn số)
    reg [PM_WIDTH-1:0] min_pm;

    always @(*) begin
        // Tìm min(pm_new_s0, pm_new_s1, pm_new_s2, pm_new_s3)
        min_pm = pm_new_s0_i;
        if (pm_new_s1_i < min_pm) min_pm = pm_new_s1_i;
        if (pm_new_s2_i < min_pm) min_pm = pm_new_s2_i;
        if (pm_new_s3_i < min_pm) min_pm = pm_new_s3_i;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // --- [FIX QUAN TRỌNG] INITIALIZATION ---
            // Encoder bắt đầu từ S0, nên Decoder cũng phải tin rằng S0 là điểm xuất phát.
            pm_current_s0_o <= {PM_WIDTH{1'b0}}; // S0 = 0 (Rất tin tưởng)
            
            // Các trạng thái khác set về Vô Cùng (MAX) để loại bỏ khả năng xuất phát từ đây
            pm_current_s1_o <= {PM_WIDTH{1'b1}}; // S1 = 255 (Max)
            pm_current_s2_o <= {PM_WIDTH{1'b1}}; // S2 = 255 (Max)
            pm_current_s3_o <= {PM_WIDTH{1'b1}}; // S3 = 255 (Max)
            
        end else if (valid_i) begin
            // Cập nhật giá trị mới và TRỪ đi min_pm (Normalization)
            pm_current_s0_o <= pm_new_s0_i - min_pm;
            pm_current_s1_o <= pm_new_s1_i - min_pm;
            pm_current_s2_o <= pm_new_s2_i - min_pm;
            pm_current_s3_o <= pm_new_s3_i - min_pm;
        end
    end

endmodule