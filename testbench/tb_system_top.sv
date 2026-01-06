`timescale 1ns/1ps

// --- DEFINE COLORS ---
`define C_RESET  "\033[0m"
`define C_RED    "\033[1;31m"
`define C_GREEN  "\033[1;32m"
`define C_BLUE   "\033[1;34m"
`define C_YELLOW "\033[1;33m"
`define C_CYAN   "\033[0;36m"
`define C_GRAY   "\033[1;30m"

module tb_system_top;

    parameter TBL = 15;
    parameter CLK_PERIOD = 10;

    reg         clk;
    reg         rst_n;
    reg         dvalid_i;
    reg  [15:0] data_i;
    wire [7:0]  data_o;
    wire        valid_o;
    wire        busy_o;

    // Queue để lưu trữ kỳ vọng
    reg [7:0]  queue_exp_data [$]; 
    reg [15:0] queue_mask [$]; 

    integer stats_sent = 0;
    integer stats_recv = 0;

    // --- DUT INSTANTIATION ---
    system_top #(.TBL(TBL)) dut (
        .clk(clk), .rst_n(rst_n),
        .dvalid_i(dvalid_i), .data_i(data_i),
        .data_o(data_o), .valid_o(valid_o), .busy_o(busy_o)
    );

    // --- CLOCK GEN ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- ENCODER TASK (Golden Model & Log chi tiết) ---
    reg [1:0] enc_state;
    task send_packet(input [7:0] val, input [15:0] err_mask);
        integer i;
        reg [1:0] sym;
        reg bit_in;
        reg [15:0] packet;
    begin
        // 1. In ra dự báo (Prediction)
        $display("%-10t | %s[SEND] Input: %h | Mask: %h | EXPECTED OUTPUT: %h%s", 
                 $time, `C_CYAN, val, err_mask, val, `C_RESET);

        // 2. Encode
        for(i=7; i>=0; i=i-1) begin
            bit_in = val[i];
            case(enc_state)
                2'b00: sym = (bit_in) ? 2'b11 : 2'b00; 
                2'b01: sym = (bit_in) ? 2'b00 : 2'b11;
                2'b10: sym = (bit_in) ? 2'b01 : 2'b10;
                2'b11: sym = (bit_in) ? 2'b10 : 2'b01;
            endcase
            enc_state = {bit_in, enc_state[1]};
            packet[2*i + 1] = sym[1];
            packet[2*i]     = sym[0];
        end
        packet = packet ^ err_mask; 

        // 3. Flow Control
        while(busy_o) @(posedge clk);
        
        dvalid_i <= 1;
        data_i   <= packet;
        @(posedge clk);
        dvalid_i <= 0;
        
        queue_exp_data.push_back(val);
        queue_mask.push_back(err_mask);
        stats_sent++;
    end
    endtask

    // --- [SPY MONITOR] SOI TÍN HIỆU NỘI BỘ ---
    // Phần này sẽ báo cho Đại ca biết dữ liệu đang chạy đến đâu
    // Lưu ý: Cú pháp dut.signal chỉ chạy được nếu simulator hỗ trợ hierarchy access
    
    always @(negedge dut.fifo_empty) 
        $display("%-10t | %s[SPY] FIFO received data (Not Empty)%s", $time, `C_GRAY, `C_RESET);

    always @(posedge dut.piso_start) 
        $display("%-10t | %s[SPY] Controller fired PISO Start%s", $time, `C_GRAY, `C_RESET);
        
    always @(posedge dut.w_core_valid) 
        $display("%-10t | %s[SPY] Bit valid entering Viterbi Core%s", $time, `C_GRAY, `C_RESET);

    // --- MAIN SCENARIO ---
    initial begin
        $display({"%s=====================================================================================%s"}, `C_YELLOW, `C_RESET);
        $display({"%s  VITERBI DEBUGGER - SPY MODE%s"}, `C_YELLOW, `C_RESET);
        $display("%-10s | %-50s", "TIME", "ACTION / EVENT");
        $display({"%s-------------------------------------------------------------------------------------%s"}, `C_YELLOW, `C_RESET);

        rst_n = 0; dvalid_i = 0; data_i = 0; enc_state = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);
        
        // Test 1: Gói tin sạch
        send_packet(8'hA5, 16'h0000); 
        
        // Test 2: Gói tin lỗi nhẹ
        send_packet(8'h3C, 16'h0001);

        // --- QUAN TRỌNG: FLUSH PIPELINE ---
        $display("%-10t | [INFO] Flushing pipeline (Sending Zeros)...", $time);
        
        // Gửi thêm 5 byte rỗng (5 * 8 = 40 bit)
        // Dư sức đẩy hết 15 bit kẹt trong TBU và gom đủ 8 bit cho SIPO
        repeat(5) send_packet(8'h00, 16'h0000);

        // --- FLUSH PIPELINE ---
        // Mục đích: Đẩy nốt những bit dữ liệu cuối cùng đang kẹt trong TBU ra ngoài
        $display("%-10t | [INFO] Flushing pipeline...", $time);
        repeat(5) send_packet(8'h00, 16'h0000); // Gửi 5 byte rỗng 

        $display("%-10t | [INFO] Waiting for pipeline drain...", $time);
        
        // Đợi lâu một chút
        repeat(500) @(posedge clk);
        
        if (stats_recv == 0) begin
            $display({"%s\n[FATAL] TIMEOUT! Khong nhan duoc goi tin nao sau 500 chu ky.%s"}, `C_RED, `C_RESET);
            $display("--- Kiem tra trang thai cuoi cung ---");
            $display("FIFO Empty: %b (1=Rong, 0=Co hang)", dut.fifo_empty);
            $display("PISO Busy:  %b (1=Dang ban, 0=Ranh)", dut.piso_busy);
            $display("PISO Start: %b", dut.piso_start);
        end
        
        $finish;
    end

    // --- CHECKER ---
    reg [7:0] exp_val;
    reg [15:0] exp_msk;

    always @(posedge clk) begin
        if (valid_o) begin
            stats_recv++;
            exp_val = queue_exp_data.pop_front();
            exp_msk = queue_mask.pop_front();

            if (data_o === exp_val) begin
                if (exp_msk == 0)
                    $display("%-10t | %s[PASS] Recv: %h == Exp: %h (Clean Match)%s", $time, `C_GREEN, data_o, exp_val, `C_RESET);
                else
                    $display("%-10t | %s[FIXED] Recv: %h == Exp: %h (Noise Mask: %h)%s", $time, `C_BLUE, data_o, exp_val, exp_msk, `C_RESET);
            end else begin
                $display("%-10t | %s[FAIL] Recv: %h != Exp: %h (Noise Mask: %h)%s", $time, `C_RED, data_o, exp_val, exp_msk, `C_RESET);
            end
        end
    end

    initial begin
        $dumpfile("system_top_wave.vcd");
        $dumpvars(0, tb_system_top);
    end

endmodule