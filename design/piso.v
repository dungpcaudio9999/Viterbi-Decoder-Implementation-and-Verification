module piso (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load_i,
    input  wire [15:0] data_parallel_i,
    output wire [1:0] data_serial_o,
    output reg        valid_serial_o
);

    reg [15:0] shift_reg;
    reg [3:0]  cnt;  // Count from 8 down to 1 for 8 shifts

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 16'b0;
            cnt            <= 4'd0;
            valid_serial_o <= 1'b0;
        end else if (load_i) begin
            shift_reg      <= data_parallel_i;
            cnt            <= 4'd8;
            valid_serial_o <= 1'b1;
        end else if (cnt != 4'd0) begin
            shift_reg <= {shift_reg[13:0], 2'b00};  // Shift left by 2, add 00 at LSB (MSB first)
            cnt       <= cnt - 1'b1;
            if (cnt == 4'd1) begin
                valid_serial_o <= 1'b0;
            end
        end
    end

    assign data_serial_o = shift_reg[15:14];  // Output the top 2 bits (MSB first)

endmodule