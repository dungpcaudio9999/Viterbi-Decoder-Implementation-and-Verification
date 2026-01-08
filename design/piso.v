module piso #(
    parameter TBL = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load_i,
    input  wire [15:0] data_parallel_i,
    
    output wire [1:0]  data_serial_o,
    output reg         valid_serial_o,
    output reg         busy_o
);
    reg [15:0] shift_reg;
    reg [3:0]  bit_cnt;

    assign data_serial_o = shift_reg[15:14]; // MSB First

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 16'b0;
            bit_cnt        <= 4'd0;
            valid_serial_o <= 1'b0;
            busy_o         <= 1'b0;
        end else begin
            // Ưu tiên nạp dữ liệu mới ngay lập tức nếu có load_i
            if (load_i) begin
                shift_reg      <= data_parallel_i;
                bit_cnt        <= 4'd8; 
                busy_o         <= 1'b1;
                valid_serial_o <= 1'b0; // Chưa valid ngay chu kỳ này vì mới nạp
            end 
            else if (busy_o) begin
                valid_serial_o <= 1'b1;
                shift_reg      <= {shift_reg[13:0], 2'b00};
                
                if (bit_cnt == 4'd1) 
                    busy_o <= 1'b0;
                else 
                    bit_cnt <= bit_cnt - 1'b1;
            end 
            else begin
                valid_serial_o <= 1'b0;
            end
        end
    end

`ifdef DEBUG_TRACE
    always @(posedge clk) begin
        // In mỗi khi PISO đang hoạt động (đang dịch bit ra serial)
        if (valid_serial_o) begin 
            $display("[TIME %0t][PISO_ACTIVE] Reg: %b | Out: %b | Busy: %b", 
                     $time, shift_reg, data_serial_o, busy_o);
        end
        // In khi có lệnh nạp byte mới
        if (load_i) begin
            $display("[TIME %0t][PISO_LOAD] Loading new byte: %h", $time, data_parallel_i);
        end
    end
`endif
endmodule

