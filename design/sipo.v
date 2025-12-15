module sipo (
    input  wire       clk,
    input  wire       rst_n,
    
    input  wire       data_serial_i,    // từ tbu.data_serial_o
    input  wire       valid_serial_i,   // từ tbu.valid_serial_o
    
    output reg  [7:0] data_parallel_o, // 8-bit dữ liệu gốc đã giải mã
    output reg        byte_ready_o      // Xung 1 clock báo hợp lệ → nối ra valid_o của system_top
);

    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;        // đếm 0 -> 7
    reg       counting;       // đang trong pha gom 8 bit

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg       <= 8'b0;
            bit_cnt         <= 4'd0;
            counting        <= 1'b0;
            data_parallel_o <= 8'b0;
            byte_ready_o    <= 1'b0;
        end
        else begin
            byte_ready_o <= 1'b0;  // mặc định xung 1ck

            if (valid_serial_i) begin
                // Bắt đầu gom từ bit đầu tiên có valid
                if (!counting) begin
                    counting <= 1'b1;
                    bit_cnt  <= 4'd1;
                    shift_reg <= {data_serial_i, 7'b0};  // bit đầu tiên vào MSB
                end
                else begin
                    shift_reg <= {shift_reg[6:0], data_serial_i};  // shift left
                    bit_cnt   <= bit_cnt + 1'b1;

                    if (bit_cnt == 4'd7) begin
                        // Đủ 8 bit → bit cuối cùng vừa vào là bit0
                        data_parallel_o <= {shift_reg[6:0], data_serial_i};
                        byte_ready_o    <= 1'b1;
                        counting        <= 1'b0;  // chờ lần traceback tiếp theo
                        bit_cnt         <= 4'd0;
                    end
                end
            end
            else begin
                // nếu valid_serial_i rớt giữa chừng → không reset (an toàn)
                // chỉ reset khi có valid mới hoặc reset toàn bộ
            end
        end
    end

endmodule