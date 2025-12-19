
module fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 32
)(
    input  wire             clk,
    input  wire             rst_n,
    
    // Giao diện ghi (vào từ dvalid_i / data_i)
    input  wire             wr_en,
    input  wire [WIDTH-1:0] din,
    output wire             full,
    
    // Giao diện đọc (ra PISO)
    input  wire             rd_en,
    output reg  [WIDTH-1:0] dout,
    output wire             empty,
    
    // Trạng thái (để debug)
    output reg [$clog2(DEPTH):0] count
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;

    // Logic quản lý cờ trạng thái
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // Logic Ghi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Logic Đọc
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Bộ đếm quản lý số lượng phần tử
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1; // Chỉ ghi
                2'b01: count <= count - 1; // Chỉ đọc
                default: count <= count;   // Không làm gì hoặc vừa ghi vừa đọc
            endcase
        end
    end

endmodule