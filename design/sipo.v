module sipo (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       data_serial_i,
    input  wire       valid_serial_i,
    output reg  [7:0] data_parallel_o,
    output reg        byte_ready_o
);

    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    
    // Biến cờ để theo dõi xem có đang gom dở byte không (Optional, nhưng tốt cho debug)
    reg       is_collecting;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg       <= 8'b0;
            bit_cnt         <= 3'd0;
            data_parallel_o <= 8'b0;
            byte_ready_o    <= 1'b0;
            is_collecting   <= 1'b0;
        end
        else begin
            // Mặc định tắt cờ ready sau 1 xung
            byte_ready_o <= 1'b0;
                
            if (valid_serial_i) begin
                // 1. Dịch bit mới vào (Shift Left: MSB first logic)
                // Bit mới vào LSB, đẩy các bit cũ lên cao
                shift_reg <= {shift_reg[6:0], data_serial_i};
                is_collecting <= 1'b1;
                
                // 2. Tăng bộ đếm
                if (bit_cnt == 3'd7) begin
                    // Đã đủ 8 bit -> Xuất kho
                    // Lưu ý: shift_reg ở dòng trên là Non-blocking, nên ở đây
                    // ta phải ghép thủ công để lấy giá trị mới nhất ngay trong chu kỳ này
                    data_parallel_o <= {shift_reg[6:0], data_serial_i};
                    byte_ready_o    <= 1'b1;
                    
                    // Reset bộ đếm để đón byte mới
                    bit_cnt       <= 3'd0;
                    is_collecting <= 1'b0; 
                end 
                else begin
                    // Chưa đủ -> Tăng đếm
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
            // TUYỆT ĐỐI KHÔNG CÓ ELSE RESET Ở ĐÂY
            // Nếu !valid_serial_i, hệ thống sẽ GIỮ NGUYÊN trạng thái (Latched)
        end
    end

endmodule