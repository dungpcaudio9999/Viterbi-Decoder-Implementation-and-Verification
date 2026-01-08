module tbu #(
    parameter TBL      = 15,
    parameter PM_WIDTH = 8
)(
    input  wire           clk,
    input  wire           rst_n,
    input  wire           valid_i,

    input  wire [3:0]          dec_bits_i,
    input  wire [PM_WIDTH-1:0] pm_s0_i,
    input  wire [PM_WIDTH-1:0] pm_s1_i,
    input  wire [PM_WIDTH-1:0] pm_s2_i,
    input  wire [PM_WIDTH-1:0] pm_s3_i,

    // SỬA: Chuyển thành WIRE để output trực tiếp từ pipeline
    output wire           data_serial_o,
    output wire           valid_serial_o, 
    output wire           busy_o
);

    reg [TBL-1:0] path_s0, path_s1, path_s2, path_s3;
    localparam PIPE_LEN = TBL; 
    reg [PIPE_LEN-1:0] valid_pipe;

    // --- 1. LOGIC MIN SELECT (Tìm đường tốt nhất) ---
    wire s0_vs_s1 = (pm_s1_i < pm_s0_i); 
    wire s2_vs_s3 = (pm_s3_i < pm_s2_i); 
    
    wire [PM_WIDTH-1:0] min_01 = s0_vs_s1 ? pm_s1_i : pm_s0_i;
    wire [PM_WIDTH-1:0] min_23 = s2_vs_s3 ? pm_s3_i : pm_s2_i;
    
    wire min01_vs_min23 = (min_01 > min_23); 
    
    reg [1:0] best_state;
    always @* begin
        best_state[1] = min01_vs_min23; 
        best_state[0] = min01_vs_min23 ? s2_vs_s3 : s0_vs_s1;
    end

    // --- 2. CẬP NHẬT ĐƯỜNG ĐI (Sequential) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            path_s0 <= 0; path_s1 <= 0; path_s2 <= 0; path_s3 <= 0;
            valid_pipe <= 0;
        end else begin
            if (valid_i) begin
                // Shift Left Topology (Chuẩn)
                path_s0 <= (dec_bits_i[0] == 0) ? {path_s0[TBL-2:0], 1'b0} : {path_s2[TBL-2:0], 1'b0};
                path_s1 <= (dec_bits_i[1] == 0) ? {path_s0[TBL-2:0], 1'b1} : {path_s2[TBL-2:0], 1'b1};
                path_s2 <= (dec_bits_i[2] == 0) ? {path_s1[TBL-2:0], 1'b0} : {path_s3[TBL-2:0], 1'b0};
                path_s3 <= (dec_bits_i[3] == 0) ? {path_s1[TBL-2:0], 1'b1} : {path_s3[TBL-2:0], 1'b1};

                // Pipeline Valid: Nạp 1
                valid_pipe <= {valid_pipe[PIPE_LEN-2:0], 1'b1};
            end else begin
                // Flush logic: Nạp 0 vào ống Valid để đẩy phần dư ra
                valid_pipe <= {valid_pipe[PIPE_LEN-2:0], 1'b0};
                // Path memory giữ nguyên hoặc shift tùy ý (không quan trọng vì valid=0 sẽ che đi)
            end
        end 
    end

    // --- 3. OUTPUT LOGIC (WIRE - Tổ hợp) ---
    // Lấy trực tiếp từ bit cuối cùng của thanh ghi, không qua Flip-Flop thêm nữa
    
    // Valid Output:
    assign valid_serial_o = valid_pipe[PIPE_LEN-1];

    // Data Output (Mux chọn từ 4 đường):
    // Force S0 logic cho an toàn, hoặc dùng Best State. 
    // Vì ACSU đã ngon, ta dùng Best State cho chuyên nghiệp.
    assign data_serial_o = (best_state == 0) ? path_s0[TBL-1] :
                           (best_state == 1) ? path_s1[TBL-1] :
                           (best_state == 2) ? path_s2[TBL-1] :
                                               path_s3[TBL-1];

    assign busy_o = 1'b0;

    `ifdef DEBUG_TRACE
    always @(posedge clk) begin
        if (valid_serial_o)
            $display("[TIME %0t][TBU] Best: %d | Data: %b | Valid: %b", 
                     $time, best_state, data_serial_o, valid_serial_o);
    end
    `endif

endmodule