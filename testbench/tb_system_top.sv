/*`timescale 1ns/1ps

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

    // --- ENCODER TASK ---
    reg [1:0] enc_state;
    task send_packet(input [7:0] val, input [15:0] err_mask);
        integer i;
        reg bit_in;
        reg [1:0] s;
        reg g1, g2;
        reg [15:0] packet;
        reg [15:0] p_tmp;
    begin
        s = 2'b00;
        $display("%-10t | %s[SEND] Input: %h | Mask: %h | EXPECTED OUTPUT: %h%s", 
                 $time, `C_CYAN, val, err_mask, val, `C_RESET);

        for(i=7; i>=0; i=i-1) begin
            bit_in = val[i];
            
            // Tính toán theo đa thức chuẩn (XOR các tap)
            // g1 = bit_in ^ s[1] ^ s[0] (7 octal)
            // g2 = bit_in ^ s[0]        (5 octal)
            g1 = bit_in ^ s[1] ^ s[0];  
            g2 = bit_in ^ s[0];
            
            // Gán vào packet: MSB gửi trước nên i=7 nằm ở bit cao
            p_tmp[2*i + 1] = g1;
            p_tmp[2*i]     = g2;
            
            // Dịch trạng thái chuẩn: bit mới vào s[1], s[1] cũ xuống s[0]
            s = {bit_in, s[1]};
        end
        packet = p_tmp ^ err_mask; 

        // Flow Control
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

    // --- SPY MONITOR ---
    always @(negedge dut.fifo_empty) 
        $display("%-10t | %s[SPY] FIFO received data (Not Empty)%s", $time, `C_GRAY, `C_RESET);
    always @(posedge dut.piso_start) 
        $display("%-10t | %s[SPY] Controller fired PISO Start%s", $time, `C_GRAY, `C_RESET);
    always @(posedge dut.w_core_valid) 
        $display("%-10t | %s[SPY] Bit valid entering Viterbi Core%s", $time, `C_GRAY, `C_RESET);

    // --- MAIN SCENARIO ---
    initial begin
        $display({"%s=====================================================================================%s"}, `C_YELLOW, `C_RESET);
        $display({"%s  VITERBI DEBUGGER - SPY MODE (FINAL)%s"}, `C_YELLOW, `C_RESET);
        $display("%-10s | %-50s", "TIME", "ACTION / EVENT");
        $display({"%s-------------------------------------------------------------------------------------%s"}, `C_YELLOW, `C_RESET);

        rst_n = 0; dvalid_i = 0; data_i = 0; enc_state = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);
        
        // --- 1. Gói tin sạch (A5) ---
        // Yêu cầu: PMU phải khởi tạo S0=0 thì gói này mới PASS
        //send_packet(8'hA5, 16'h0000); 
        
        // --- 2. Gói tin lỗi nhẹ (3C) ---
        // Yêu cầu: TBU phải có logic Timing chuẩn (Reg Out, TBL Pipe) thì gói này mới PASS
        send_packet(8'h0F, 16'h0000);

        // --- 3. Flush Pipeline ---
        // Gửi 5 gói rỗng để đẩy dữ liệu ra. Chỉ cần làm 1 lần.
        $display("%-10t | [INFO] Flushing pipeline (Sending Zeros)...", $time);
        repeat(5) send_packet(8'h00, 16'h0000);

        $display("%-10t | [INFO] Waiting for pipeline drain...", $time);
        repeat(500) @(posedge clk);
        
        if (stats_recv < 2) begin
            $display({"%s\n[FATAL] TIMEOUT! Chưa nhận đủ gói tin chính.%s"}, `C_RED, `C_RESET);
        end else begin
             $display({"%s\n[SUCCESS] Đã hoàn thành bài test.%s"}, `C_GREEN, `C_RESET);
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
*/
`timescale 1ns/1ps

module tb_system_top;

    // =================================================================
    // 1. KHAI BÁO TÍN HIỆU
    // =================================================================
    reg         clk;
    reg         rst_n;
    
    // Input
    reg         dvalid_i;
    reg  [15:0] data_i;
    
    // Output
    wire [7:0]  data_o;
    wire        valid_o;
    wire        busy_o;

    // Biến phụ trợ để đếm gói tin
    integer out_cnt = 0;

    // =================================================================
    // 2. KẾT NỐI MODULE (DUT - Device Under Test)
    // =================================================================
    system_top #(
        .TBL(15) // Traceback Length
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .dvalid_i(dvalid_i),
        .data_i(data_i),
        .data_o(data_o),
        .valid_o(valid_o),
        .busy_o(busy_o)
    );

    // =================================================================
    // 3. TẠO CLOCK (100MHz - Chu kỳ 10ns)
    // =================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // =================================================================
    // 4. CHƯƠNG TRÌNH CHÍNH (DRIVER)
    // =================================================================
    initial begin
        // --- A. Khởi tạo ---
        $display("\n[TIME %0t] --- SIMULATION START ---", $time);
        rst_n    = 0;
        dvalid_i = 0;
        data_i   = 0;

        // --- B. Reset hệ thống ---
        #50; 
        rst_n = 1;
        $display("[TIME %0t] System Reset Done. Waiting for stable...", $time);
        #50;

        // --- C. Nạp dữ liệu (Gói E217) ---
        // Gọi task send_packet bên dưới
        send_packet(16'hE217);

        // --- D. Chờ kết quả ---
        // Viterbi cần thời gian traceback + flush nên phải chờ đủ lâu
        $display("[TIME %0t] Data sent. Waiting for output...", $time);
        
        // Chờ khoảng 1000ns (hoặc lâu hơn tùy độ dài traceback)
        #2000; 

        // --- E. Kết thúc ---
        $display("[TIME %0t] --- SIMULATION FINISHED ---", $time);
        $finish;
    end

    // =================================================================
    // TASK: Gửi gói tin an toàn (Có kiểm tra Busy)
    // =================================================================
    task send_packet(input [15:0] data_in);
        begin
            // 1. Chờ đến khi hệ thống rảnh (FIFO không full)
            wait(busy_o == 0);
            
            // 2. Đồng bộ với cạnh lên clock để gửi tín hiệu chuẩn
            @(posedge clk);
            dvalid_i = 1;
            data_i   = data_in;
            $display("[TIME %0t] [INPUT] Sending Packet: %h", $time, data_in);

            // 3. Giữ tín hiệu trong 1 chu kỳ clock
            @(posedge clk);
            dvalid_i = 0;
            data_i   = 0;
        end
    endtask

    // =================================================================
    // 5. GIÁM SÁT KẾT QUẢ (MONITOR)
    // =================================================================
    always @(posedge clk) begin
        if (valid_o) begin
            out_cnt = out_cnt + 1;
            
            // In ra màn hình console
            $write("[TIME %0t] [OUTPUT #%0d] Received Data: %h (Binary: %b) ", $time, out_cnt, data_o, data_o);

            // Tự động kiểm tra kết quả
            if (data_o == 8'h35) begin
                $display("--> [PASS] EXACT MATCH! (Day la du lieu Dai ca can)"); 
            end else if (data_o == 8'h00) begin
                $display("--> [INFO] Pipeline Padding/Flush (Co the bo qua)");
            end else begin
                $display("--> [WARN] Unexpected Data");
            end
        end
    end

    // (Tùy chọn) Dump sóng nếu dùng GTKWave/ModelSim
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_system_top);
    end

endmodule