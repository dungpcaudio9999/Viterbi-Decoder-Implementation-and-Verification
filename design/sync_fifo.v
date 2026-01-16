module sync_fifo #(
    parameter DATA_WIDTH = 16,
    parameter FIFO_DEPTH = 16
)(
    input  wire             clk,
    input  wire             rst_n,
    
    // Giao diện ghi (Nối với Input bên ngoài)
    input  wire             wr_en_i,
    input  wire [DATA_WIDTH-1:0] wr_data_i,
    output wire             full_o,
    
    // Giao diện đọc (Nối với Controller bên trong)
    input  wire             rd_en_i,
    output reg  [DATA_WIDTH-1:0] rd_data_o,
    output wire             empty_o
);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr;
    reg [$clog2(FIFO_DEPTH):0]   count;

    assign full_o  = (count == FIFO_DEPTH);
    assign empty_o = (count == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            rd_data_o   <= 0;
        end else begin
            // Logic Ghi
            if (wr_en_i && !full_o) begin
                mem[wr_ptr] <= wr_data_i;
                wr_ptr      <= wr_ptr + 1'b1;
            end

            // Logic Đọc
            if (rd_en_i && !empty_o) begin
                rd_data_o   <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Cập nhật bộ đếm số lượng
            if (wr_en_i && !full_o && !(rd_en_i && !empty_o))
                count <= count + 1;
            else if (rd_en_i && !empty_o && !(wr_en_i && !full_o))
                count <= count - 1;
        end
    end

endmodule