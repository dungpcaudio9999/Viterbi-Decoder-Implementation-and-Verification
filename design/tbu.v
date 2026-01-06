/*
 * MODULE: tbu
 * CHỨC NĂNG: Traceback Unit - ROLLBACK TO GOLDEN VERSION
 * UPDATE: 
 * 1. Quay lại dùng Output Register (always @posedge) để đồng bộ nhịp với Valid.
 * 2. Giữ logic PAUSE để chống Timeout.
 * 3. Giữ độ dài ống chuẩn TBL (15) -> Khớp bit 100%.
 */
module tbu #(
    parameter TBL      = 15,
    parameter PM_WIDTH = 8
)(
    input  wire           clk,
    input  wire           rst_n,
    input  wire           valid_i,

    input  wire [3:0]     dec_bits_i,  
    input  wire [PM_WIDTH-1:0] pm_s0_i,
    input  wire [PM_WIDTH-1:0] pm_s1_i,
    input  wire [PM_WIDTH-1:0] pm_s2_i,
    input  wire [PM_WIDTH-1:0] pm_s3_i,

    output reg            data_serial_o, // Dùng REG (Flip-flop) để khớp nhịp
    output wire           valid_serial_o, 
    output wire           busy_o
);

    reg [TBL-1:0] path_s0;
    reg [TBL-1:0] path_s1;
    reg [TBL-1:0] path_s2;
    reg [TBL-1:0] path_s3;

    // Độ dài chuẩn, không cộng trừ gì cả
    localparam PIPE_LEN = TBL; 
    reg [PIPE_LEN-1:0] valid_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            path_s0 <= 0; path_s1 <= 0; path_s2 <= 0; path_s3 <= 0;
            valid_pipe <= 0;
            data_serial_o <= 0;
        end else if (valid_i) begin
            // --- LOGIC ĐỒNG BỘ (PAUSE) ---
            
            // 1. Cập nhật đường đi
            path_s0 <= (dec_bits_i[0] == 0) ? {path_s0[TBL-2:0], 1'b0} : {path_s1[TBL-2:0], 1'b0};
            path_s1 <= (dec_bits_i[1] == 0) ? {path_s2[TBL-2:0], 1'b0} : {path_s3[TBL-2:0], 1'b0};
            path_s2 <= (dec_bits_i[2] == 0) ? {path_s0[TBL-2:0], 1'b1} : {path_s1[TBL-2:0], 1'b1};
            path_s3 <= (dec_bits_i[3] == 0) ? {path_s2[TBL-2:0], 1'b1} : {path_s3[TBL-2:0], 1'b1};
            
            // 2. Cập nhật Valid Pipe
            valid_pipe <= {valid_pipe[PIPE_LEN-2:0], 1'b1};

            // 3. Cập nhật Data Output (Vote)
            // Vì nằm trong always @posedge nên nó sẽ có độ trễ 1 nhịp
            // Khớp hoàn toàn với độ trễ 1 nhịp của valid_pipe
            if (pm_s0_i <= pm_s1_i && pm_s0_i <= pm_s2_i && pm_s0_i <= pm_s3_i)
                data_serial_o <= path_s0[TBL-1];
            else if (pm_s1_i <= pm_s2_i && pm_s1_i <= pm_s3_i)
                data_serial_o <= path_s1[TBL-1];
            else if (pm_s2_i <= pm_s3_i)
                data_serial_o <= path_s2[TBL-1];
            else
                data_serial_o <= path_s3[TBL-1];
        end 
    end

    // Valid output logic
    assign valid_serial_o = valid_pipe[PIPE_LEN-1] & valid_i; 

    assign busy_o = 1'b0;

endmodule