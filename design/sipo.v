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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0; bit_cnt <= 0; byte_ready_o <= 0; data_parallel_o <= 0;
        end else begin
            byte_ready_o <= 0;
            if (valid_serial_i) begin
                // Shift Right (LSB vào trước -> nằm ở bit thấp)
                // Hoặc Shift Right (LSB vào trước -> vào [7] rồi tụt xuống [0])
                // Chuẩn: {in, reg[7:1]} -> In vào 7.
                shift_reg <= {data_serial_i, shift_reg[7:1]};
                
                if (bit_cnt == 3'd7) begin
                    data_parallel_o <= {data_serial_i, shift_reg[7:1]};
                    byte_ready_o    <= 1'b1;
                    bit_cnt         <= 0;
                end else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end
    // ... debug ...
endmodule