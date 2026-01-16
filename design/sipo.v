module sipo (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_serial_i,
    input  wire        valid_serial_i,
    output reg  [7:0] data_parallel_o,
    output reg        byte_ready_o
);

    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg       <= 8'b0;
            bit_cnt         <= 3'd0;
            data_parallel_o <= 8'b0;
            byte_ready_o    <= 1'b0;
        end
        else begin
            byte_ready_o <= 1'b0;
                
            if (valid_serial_i) begin
                // --- SỬA ĐỔI QUAN TRỌNG ---
                // Dịch PHẢI (Shift Right) để khớp với thứ tự Traceback
                // Bit vào trước (LSB) sẽ bị đẩy dần xuống vị trí [0]
                // Bit vào sau (MSB) sẽ nằm ở vị trí cao [7]
                shift_reg <= {data_serial_i, shift_reg[7:1]};
                
                if (bit_cnt == 3'd7) begin
                    // Output ngay lập tức
                    // Ghép bit mới nhất vào vị trí MSB [7], các bit cũ dồn xuống [6:0]
                    data_parallel_o <= {data_serial_i, shift_reg[7:1]};
                    byte_ready_o    <= 1'b1;
                    
                    bit_cnt         <= 3'd0;
                end 
                else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

endmodule