module sipo (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_serial_i,  // Bit from TBU
    input  wire        valid_serial_i, // Valid flag from TBU
    output reg [7:0]   data_parallel_o,
    output reg         byte_ready_o    // Indicates 8 bits are ready
);

    reg [2:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_parallel_o <= 8'b0;
            byte_ready_o    <= 1'b0;
            count           <= 3'b0;
        end else begin
            byte_ready_o <= 1'b0; // Default low
            if (valid_serial_i) begin
                // Note: Traceback usually returns bits in reverse order (newest -> oldest)
                // Or forward depending on how TBU outputs.
                // In the above TBU, we trace from end to start -> Received bit is the last bit of the packet (LSB or MSB depending on endianness).
                // Assuming we shift bits from MSB to LSB or vice versa.
                // To keep original packet order (usually sends bit 0 first), and TBU returns bit 7 first...
                // We shift right:
                data_parallel_o <= {data_serial_i, data_parallel_o[7:1]}; 
                
                // 3. Bit counter management
                if (count == 3'd7) begin
                    byte_ready_o <= 1'b1;
                    count        <= 3'b0; // Reset counter when 8 bits are received
                end else begin
                    byte_ready_o <= 1'b0;
                    count        <= count + 1'b1;
                end
            end else begin
                // 4. Important ELSE branch: Keep all values when data is not ready
                data_parallel_o <= data_parallel_o;
                count           <= count;
                byte_ready_o    <= 1'b0; // Always ensure ready = 0 when there are no new bits
            end
        end
    end

endmodule
