`define DEBUG_TRACE  // Comment dòng này lại nếu muốn tắt debug

`include "sync_fifo.v"
`include "viterbi_core.v"
// Lưu ý: viterbi_core đã bao gồm các include con (piso, bmu, acsu, pmu, tbu, sipo)
// Nếu trình biên dịch báo lỗi double include,  hãy comment dòng include viterbi_core lại
// hoặc dùng guard ifndef trong các file con.

module system_top #(
    parameter TBL = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // INPUT (Nối vào FIFO từ Testbench/Hệ thống ngoài)
    input  wire        dvalid_i,
    input  wire [15:0] data_i,
    
    // OUTPUT (Kết quả giải mã)
    output wire [7:0]  data_o,
    output wire        valid_o,
    
    // Báo bận (Chỉ bận khi FIFO đầy, không bao giờ bận do xử lý nữa)
    output wire        busy_o  
);

    // =================================================================
    // 1. DÂY NỐI NỘI BỘ
    // =================================================================
    
    // FIFO -> Controller
    wire        fifo_full;
    wire        fifo_empty;
    wire [15:0] fifo_rdata;
    reg         fifo_ren;

    // Controller -> PISO
    reg         piso_start;
    reg  [15:0] piso_din;
    wire        piso_busy; // PISO báo bận khi đang dịch bit

    // PISO -> CORE -> SIPO
    wire        w_core_valid;
    wire [1:0]  w_core_data;
    wire        w_sipo_bit;
    wire        w_sipo_valid;
    
    // TBU Busy (Trong kiến trúc mới, dây này luôn bằng 0)
    wire        w_tbu_busy; 

    // Output busy_o của hệ thống bây giờ chỉ phụ thuộc vào FIFO
    assign busy_o = fifo_full;

    // =================================================================
    // 2. INSTANCE FIFO (Bộ đệm đầu vào)
    // =================================================================
    sync_fifo #(
        .DATA_WIDTH(16),
        .FIFO_DEPTH(16)
    ) fifo_inst (
        .clk(clk), 
        .rst_n(rst_n),
        
        // Write side
        .wr_en_i(dvalid_i), 
        .wr_data_i(data_i), 
        .full_o(fifo_full),
        
        // Read side
        .rd_en_i(fifo_ren), 
        .rd_data_o(fifo_rdata), 
        .empty_o(fifo_empty)
    );

    // =================================================================
    // 3. CONTROLLER (FSM: FIFO -> WAIT -> PISO -> AUTO FLUSH)
    // =================================================================
    
    reg [2:0] fsm_state; 
    reg [4:0] flush_cnt;

    // Thêm trạng thái S_WAIT
    // Thêm S_WAIT_BUSY vào danh sách
    localparam S_CHECK = 0, S_WAIT = 1, S_LOAD = 2, S_FIRE = 3, S_WAIT_BUSY = 4;
    localparam FLUSH_LIMIT = 32; // Tăng limit lên chút cho chắc

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state  <= S_CHECK;
            fifo_ren   <= 0;
            piso_start <= 0;
            piso_din   <= 0;
            flush_cnt  <= 0;
        end else begin
            case (fsm_state)
                S_CHECK: begin
                    piso_start <= 0; 
                    
                    if (!piso_busy) begin
                        if (!fifo_empty) begin
                            // 1. CÓ HÀNG: Đọc FIFO
                            fifo_ren  <= 1;
                            flush_cnt <= 0;
                            // Sửa lỗi: Không nhảy sang LOAD ngay, mà phải sang WAIT
                            fsm_state <= S_WAIT; 
                        end
                        else if (flush_cnt < FLUSH_LIMIT) begin
                            // 2. HẾT HÀNG: Auto Flush (Nạp số 0)
                            piso_din  <= 16'd0; 
                            fsm_state <= S_FIRE; // Flush thì không cần Wait
                            flush_cnt <= flush_cnt + 1;
                        end
                    end
                end

                S_WAIT: begin
                    // Trạng thái này để chờ RAM của FIFO phản hồi
                    fifo_ren  <= 0; // Tắt lệnh đọc (pulse 1 nhịp là đủ)
                    fsm_state <= S_LOAD;
                end

                S_LOAD: begin
                    // Lúc này fifo_rdata mới thực sự có dữ liệu đúng
                    piso_din  <= fifo_rdata; 
                    fsm_state <= S_FIRE;
                end

                S_FIRE: begin
                    piso_start <= 1;        
                    fsm_state  <= S_WAIT_BUSY;  
                end
                
                S_WAIT_BUSY: begin
                    piso_start <= 0; // Hạ lệnh start xuống
                    // Bây giờ PISO chắc chắn đã nhận lệnh và dựng busy lên rồi
                    // Quay về CHECK để đợi nó làm xong việc
                    fsm_state  <= S_CHECK;
                end
            endcase
        end
    end

    // =================================================================
    // 4. INSTANCE PISO (Parallel In - Serial Out)
    // =================================================================
    piso #(
        .TBL(TBL)
    ) piso_inst (
        .clk(clk), 
        .rst_n(rst_n),
        
        // Input từ Controller
        .load_i(piso_start),          
        .data_parallel_i(piso_din),   
        
        // Output báo bận (để Controller biết đường chờ)
        .busy_o(piso_busy),           
        
        // Output dữ liệu nối sang Core
        .valid_serial_o(w_core_valid),
        .data_serial_o(w_core_data)   
    );

    // =================================================================
    // 5. INSTANCE VITERBI CORE (Pipeline Version)
    // =================================================================
    viterbi_core #(
        .TBL(TBL),
        .PM_WIDTH(8)
    ) core_inst (
        .clk(clk), 
        .rst_n(rst_n),
        
        // Input từ PISO
        .valid_i(w_core_valid), 
        .data_core_i(w_core_data),
        
        // Output sang SIPO
        .data_serial_o(w_sipo_bit), 
        .valid_serial_o(w_sipo_valid),
        
        // Busy (Luôn bằng 0 ở bản mới, nối vào cho đủ bộ)
        .busy_o(w_tbu_busy) 
    );

    // =================================================================
    // 6. INSTANCE SIPO (Serial In - Parallel Out)
    // =================================================================
    sipo sipo_inst (
        .clk(clk), 
        .rst_n(rst_n),
        .data_serial_i(w_sipo_bit), 
        .valid_serial_i(w_sipo_valid),
        
        // Output cuối cùng ra ngoài
        .data_parallel_o(data_o), 
        .byte_ready_o(valid_o)
    );

endmodule