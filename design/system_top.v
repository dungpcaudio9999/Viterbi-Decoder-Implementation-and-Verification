/*
 * MODULE: system_top
 * CHỨC NĂNG: Lõi IP giải mã Viterbi K=3, R=1/2 hoàn chỉnh.
 * KIẾN TRÚC: PISO -> Viterbi Core -> SIPO
 * Nhận 16-bit song song, trả về 8-bit song song.
 */
 /*
 `include "piso.v"
 `include "acsu.v"
 `include "pmu.v"
 `include "tbu.v"
 `include "sipo.v"
 */
 `include "viterbi_core.v"
 `include "fifo.v"

module system_top #(
    // Tham số có thể được override khi gọi module
    parameter TBL      = 15, // Traceback Length
    parameter PM_WIDTH = 8   // Độ rộng bit của Path Metric
)(
    // --- Cổng Hệ thống ---
    input  wire           clk,
    input  wire           rst_n,
    
    // --- Cổng Đầu vào (Parallel) ---
    input  wire           dvalid_i, // Báo 16-bit data_i hợp lệ
    input  wire [15:0]    data_i,
    
    // --- Cổng Đầu ra (Parallel) ---
    output wire [7:0]     data_o,   // 8-bit kết quả
    output wire           valid_o,  // Báo data_o hợp lệ (1-cycle pulse)
    output wire           busy_o    // Báo hệ thống đang xử lý
);

    // =================================================================
    // 1. TÍN HIỆU NỘI BỘ (Dây nối giữa các khối)
    // =================================================================

    // Dây nối FIFO
    wire [15:0] w_fifo_out_data;
    wire        w_fifo_empty;
    wire        w_fifo_full;
    wire        w_fifo_rd_en;

    // PISO sẽ nạp dữ liệu khi FIFO nhả hàng (delay 1 clock do rd_ptr của FIFO)
    reg r_piso_load;
    always @(posedge clk) r_piso_load <= w_fifo_rd_en;

    // Tín hiệu Handshake
    wire            w_piso_load;      // Xung 1-clock (từ FSM) báo PISO nạp 16-bit
    wire            w_sipo_byte_ready; // Xung 1-clock (từ SIPO) báo đã xong 8-bit

    // Luồng dữ liệu PISO -> CORE (Nối tiếp 2-bit)
    wire [1:0]      w_core_in_data;
    wire            w_core_in_valid;

    // Luồng dữ liệu CORE -> SIPO (Nối tiếp 1-bit)
    wire            w_core_out_data;
    wire            w_core_out_valid;

    // =================================================================
    // 2. FSM ĐIỀU KHIỂN `busy_o`
    // =================================================================
    // FSM này quản lý trạng thái bận của TOÀN BỘ HỆ THỐNG.
    
    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;
    
    reg r_busy_state;

    // `busy_o` chính là trạng thái FSM
    assign busy_o = r_busy_state; 
    
    // Chỉ "nạp" (load) khi rảnh VÀ có lệnh
    assign w_piso_load = (r_busy_state == S_IDLE) && dvalid_i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_busy_state <= S_IDLE;
        end
        else begin
            case (r_busy_state)
                S_IDLE: begin
                    if (w_piso_load) begin
                        r_busy_state <= S_BUSY; // Bắt đầu bận
                    end
                end
                
                S_BUSY: begin
                    if (w_sipo_byte_ready) begin
                        r_busy_state <= S_IDLE; // Xong việc, quay về rảnh
                    end
                end
            endcase
        end
    end

    // =================================================================
    // 3. KẾT NỐI (INSTANTIATION) CÁC KHỐI CON
    // =================================================================

    // -----  KHỐI 0: FIFO (nhận dữ liệu hàng loạt từ ngoài)  ----- //
    fifo #(.WIDTH(16), .DEPTH(32)) fifo_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .wr_en  (dvalid_i),    // Cứ có dvalid_i từ ngoài là đẩy vào FIFO
        .din    (data_i),
        .full   (w_fifo_full), // Có thể nối ra cổng busy_o để báo "đầy, đừng gửi nữa"
        .rd_en  (w_fifo_rd_en),
        .dout   (w_fifo_out_data),
        .empty  (w_fifo_empty),
        .count  ()
    );
    

    // --- KHỐI 1: PISO (Nhận 16-bit) ---
    piso #(
        .TBL(TBL)
    ) piso_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .load_i           (r_piso_load),      // Lệnh nạp (từ FSM)
        .data_parallel_i  (w_fifo_out_data),           // 16-bit vào

        .data_serial_o    (w_core_in_data),   // -> Gửi 2-bit cho CORE
        .valid_serial_o   (w_core_in_valid)   // -> Gửi valid cho CORE
    );

    // --- KHỐI 2: LÕI VITERBI (Bọc BMU, ACSU, PMU, TBU) ---
    viterbi_core #(
        .TBL              (TBL),
        .PM_WIDTH         (PM_WIDTH)
    ) core_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .valid_i          (w_core_in_valid),  // <- Nhận valid từ PISO
        .data_core_i           (w_core_in_data),   // <- Nhận 2-bit từ PISO

        .data_serial_o    (w_core_out_data),  // -> Gửi 1-bit cho SIPO
        .valid_serial_o   (w_core_out_valid)  // -> Gửi valid cho SIPO
    );

    // --- KHỐI 3: SIPO (Nhận 8 lần 1-bit, "xả" 1 lần 8-bit) ---
    sipo sipo_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .data_serial_i    (w_core_out_data),  // <- Nhận 1-bit từ CORE
        .valid_serial_i   (w_core_out_valid), // <- Nhận valid từ CORE

        .data_parallel_o  (data_o),           // -> Ra TOP
        .byte_ready_o     (w_sipo_byte_ready) // -> Báo cho FSM
    );

    // Logic rút dữ liệu
    assign w_fifo_rd_en = (!busy_o) && (!w_fifo_empty);

    // --- Gán cổng đầu ra cuối cùng ---
    assign valid_o = w_sipo_byte_ready;

endmodule 