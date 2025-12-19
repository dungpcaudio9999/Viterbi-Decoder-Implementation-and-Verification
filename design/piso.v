module piso #(
    parameter TBL = 15
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load_i,
    input  wire [15:0] data_parallel_i,
    output wire [1:0]  data_serial_o,
    output reg         valid_serial_o
);

    // --- CẤU HÌNH TIMING ---
    localparam TARGET_GAP = TBL + 2; 
    localparam LOAD_VAL = TARGET_GAP - 1;
    localparam CNT_WIDTH = $clog2(LOAD_VAL + 1);

    reg [15:0]          shift_reg;
    reg [3:0]           bit_cnt;
    reg [CNT_WIDTH-1:0] wait_cnt;
    reg                 busy;

    // DEBUG
    initial begin
        $display("PISO FIX APPLIED: Always shift after valid.");
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 16'b0;
            bit_cnt        <= 4'd0;
            wait_cnt       <= {CNT_WIDTH{1'b0}};
            valid_serial_o <= 1'b0;
            busy           <= 1'b0;
        end else begin
            valid_serial_o <= 1'b0; 

            if (load_i && !busy) begin
                shift_reg <= data_parallel_i;
                bit_cnt   <= 4'd8;
                busy      <= 1'b1;
                wait_cnt  <= {CNT_WIDTH{1'b0}}; 
                $display("[PISO DEBUG] Loaded Data: 0x%h", data_parallel_i);
            end else if (busy) begin
                if (wait_cnt == 0) begin
                    // 1. Bắn dữ liệu ra
                    valid_serial_o <= 1'b1;
                    
                    // 2. DỊCH BIT NGAY LẬP TỨC (SỬA LỖI TẠI ĐÂY)
                    // Không cần kiểm tra bit_cnt != 8 nữa. 
                    // Cứ bắn xong là dịch để cặp tiếp theo trồi lên đầu.
                    shift_reg <= {shift_reg[13:0], 2'b00}; // MSB First
                    
                    // DEBUG: In ra để xem sau khi dịch nó còn gì
                    $display("[PISO DEBUG] Sent pair. Shifted. New Head=2'b%b", shift_reg[13:12]);

                    // 3. Quản lý bộ đếm
                    if (bit_cnt == 4'd1) begin
                        busy <= 1'b0;
                        $display("[PISO DEBUG] DONE. All bits sent.");
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                        wait_cnt <= LOAD_VAL[CNT_WIDTH-1:0]; 
                    end
                end else begin
                    wait_cnt <= wait_cnt - 1'b1;
                end
            end
        end
    end

    assign data_serial_o = shift_reg[15:14];

endmodule