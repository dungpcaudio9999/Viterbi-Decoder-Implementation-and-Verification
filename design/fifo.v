module fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 16
)(
    input  wire             clk,
    input  wire             rst_n,
    
    // Giao diện ghi (Nối với Input bên ngoài)
    input  wire             wr_en,
    input  wire [WIDTH-1:0] din,
    output wire             full,
    
    // Giao diện đọc (Nối với Controller bên trong)
    input  wire             rd_en,
    output reg  [WIDTH-1:0] dout,
    output wire             empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    reg [$clog2(DEPTH):0]   count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= 0;
        end else begin
            // Logic Ghi
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1'b1;
            end

            // Logic Đọc
            if (rd_en && !empty) begin
                dout   <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Cập nhật bộ đếm số lượng
            if (wr_en && !full && !(rd_en && !empty))
                count <= count + 1;
            else if (rd_en && !empty && !(wr_en && !full))
                count <= count - 1;
        end
    end

endmodule