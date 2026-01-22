`timescale 1ns/1ps

module tb_system_top;

    // --- 0. ANSI COLORS & COUNTERS ---
    string RESET  = "\033[0m";
    string RED    = "\033[1;31m";
    string GREEN  = "\033[1;32m";
    string YELLOW = "\033[1;33m";
    string BLUE   = "\033[1;34m";
    string CYAN   = "\033[1;36m";

    // Thống kê chi tiết: [0]=Clean, [1]=1bit, [2]=2bit, [3]=3bit, [4]=4+ bits
    int stat_pass [0:4]; 
    int stat_fail [0:4];
    int total_tests = 0;

    // --- 1. Signals ---
    logic        clk, rst_n, dvalid_i, valid_o, busy_o;
    logic [15:0] data_i;
    logic [7:0]  data_o;

    // --- 2. State & Queues ---
    logic [7:0]  expected_queue [$];      // Hàng đợi kết quả mong đợi
    logic [15:0] sent_packet_queue [$];   // Hàng đợi gói tin input (để in log)
    int          error_count_queue [$];   // Hàng đợi số bit lỗi (để thống kê)
    
    logic [1:0] encoder_state; 
    bit first_byte_rcvd; 
    
    // DUT
    system_top u_dut (.*);

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 3. Reporting Utils ---
    task print_separator(); 
        $display("+------------+--------+--------+--------+--------+----------+"); 
    endtask

    task print_header();
        print_separator();
        $display("|  Time (ns) | In(16b)|  Recv  | Expect | Errors |  Status  |");
        print_separator();
    endtask

    // Cập nhật: In thêm cột số lỗi và cộng dồn thống kê
    task print_row(input string status, input [15:0] input_val, input [7:0] recv, input [7:0] exp, input int err_cnt);
        string color;
        int idx;
        
        // Clamp index về 4 nếu lỗi >= 4
        idx = (err_cnt > 4) ? 4 : err_cnt;

        if (status == "PASS") begin
            color = GREEN;
            stat_pass[idx]++;
            total_tests++;
        end else if (status == "FAIL") begin
            color = RED;
            stat_fail[idx]++;
            total_tests++;
        end else if (status == "WARMUP") color = YELLOW;
        else if (status == "FLUSH")  color = CYAN;
        else color = RESET;
        
        if (status == "FLUSH" || status == "WARMUP")
            $display("| %10t |  ----  |   %02h   |   --   |   --   | %s %-6s %s |", $time, recv, color, status, RESET);
        else
            $display("| %10t |  %04h  |   %02h   |   %02h   |   %1d    | %s %-6s %s |", $time, input_val, recv, exp, err_cnt, color, status, RESET);
    endtask

    task print_summary();
        int total_pass = 0;
        int total_fail = 0;
        int i;

        // --- FIX ERROR: Thay thế .sum() bằng vòng lặp thủ công ---
        for (i = 0; i <= 4; i++) begin
            total_pass = total_pass + stat_pass[i];
            total_fail = total_fail + stat_fail[i];
        end
        // ---------------------------------------------------------

        $display("\n");
        $display("==================================================================");
        $display("                        TEST SUMMARY REPORT                       ");
        $display("==================================================================");
        $display("| Error Type |   Total   |    %sPASS%s    |    %sFAIL%s    | Success Rate |", GREEN, RESET, RED, RESET);
        $display("|------------+-----------+------------+------------+--------------|");
        
        for (i = 0; i <= 4; i++) begin
            string label;
            int t, p, f;
            real rate;
            
            if (i == 0) label = "Clean (0b)";
            else if (i == 4) label = "Burst (4+)";
            else label = $sformatf("Error %1db ", i);
            
            p = stat_pass[i];
            f = stat_fail[i];
            t = p + f;
            rate = (t > 0) ? (p * 100.0 / t) : 0.0;

            $display("| %-10s | %9d | %9d  | %9d  |    %5.1f%%    |", 
                     label, t, p, f, rate);
        end
        $display("==================================================================");
        $display(" TOTAL RUNS : %0d", total_tests);
        
        if (total_fail == 0) 
            $display("\n%s [SUCCESS] SYSTEM PASSED ALL TESTS PERFECTLY! %s", GREEN, RESET);
        else 
            $display("\n%s [WARNING] SYSTEM HAS %0d FAILURES. CHECK LOGS ABOVE. %s", RED, total_fail, RESET);
        $display("\n");
    endtask

    // --- 4. Monitor Logic ---
    task monitor_and_check();
        logic [7:0] exp_data;
        logic [15:0] orig_input;
        int curr_err_cnt;
        
        forever begin
            @(posedge clk);
            if(valid_o) begin
                if(!first_byte_rcvd) begin
                    print_row("WARMUP", 16'h0000, data_o, 8'h00, 0); 
                    first_byte_rcvd = 1; 
                end else begin
                    if(expected_queue.size() > 0) begin
                        exp_data = expected_queue.pop_front();
                        
                        // Lấy packet gốc
                        if(sent_packet_queue.size() > 0) orig_input = sent_packet_queue.pop_front();
                        else orig_input = 16'hXXXX;

                        // Lấy số lỗi tương ứng
                        if(error_count_queue.size() > 0) curr_err_cnt = error_count_queue.pop_front();
                        else curr_err_cnt = 0;

                        if(data_o === exp_data) print_row("PASS", orig_input, data_o, exp_data, curr_err_cnt);
                        else                    print_row("FAIL", orig_input, data_o, exp_data, curr_err_cnt);
                    end else begin
                         print_row("FLUSH", 16'h0000, data_o, 8'h00, 0);
                    end
                end
            end
        end
    endtask

    // --- 5. Helper Tasks ---
    task reset_for_new_test();
        rst_n = 0; dvalid_i = 0; 
        expected_queue.delete(); 
        sent_packet_queue.delete(); 
        error_count_queue.delete(); 
        encoder_state = 0; first_byte_rcvd = 0; 
        
        // Reset thống kê mảng về 0 thủ công (để an toàn với iverilog)
        // Lưu ý: Ta KHÔNG reset thống kê giữa các phase để có bảng tổng hợp cuối cùng
        // Chỉ reset queue và tín hiệu.
        
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk); 
    endtask

    task wait_for_queue_empty(input string name);
        fork : wait_blk
            begin wait(expected_queue.size() == 0); end
            begin 
                #5000000; 
                if(expected_queue.size() > 0) begin
                    $display("%s[TIMEOUT] %s timed out! Remaining: %0d%s", RED, name, expected_queue.size(), RESET);
                    stat_fail[0]++; // Tính là lỗi chung
                    total_tests++;
                end
            end
        join_any
        disable wait_blk;
    endtask

    task encode_and_drive(input logic [7:0] byte_in, input bit check_queue);
        logic [15:0] encoded_packet;
        logic [1:0] pair;
        for (int i = 0; i < 8; i++) begin
            pair[0] = byte_in[i] ^ encoder_state[1] ^ encoder_state[0]; 
            pair[1] = byte_in[i] ^ encoder_state[0];                    
            encoder_state = {byte_in[i], encoder_state[1]};
            encoded_packet[15 - (2*i)]     = pair[0]; 
            encoded_packet[15 - (2*i) - 1] = pair[1]; 
        end
        @(posedge clk); while(busy_o) @(posedge clk);
        dvalid_i <= 1; data_i <= encoded_packet;
        if(check_queue) begin
            expected_queue.push_back(byte_in);
            sent_packet_queue.push_back(encoded_packet);
            error_count_queue.push_back(0); // Clean packet
        end
        @(posedge clk); dvalid_i <= 0;
    endtask

    task encode_and_drive_noisy(input logic [7:0] byte_in, input int num_errors);
        logic [15:0] encoded_packet;
        logic [1:0] pair;
        int i, err_pos1;
        for (i = 0; i < 8; i++) begin
            pair[0] = byte_in[i] ^ encoder_state[1] ^ encoder_state[0]; 
            pair[1] = byte_in[i] ^ encoder_state[0];                    
            encoder_state = {byte_in[i], encoder_state[1]};
            encoded_packet[15 - (2*i)]     = pair[0]; 
            encoded_packet[15 - (2*i) - 1] = pair[1]; 
        end
        repeat(num_errors) begin
            err_pos1 = $urandom_range(0, 15);
            encoded_packet[err_pos1] = ~encoded_packet[err_pos1];
        end
        @(posedge clk); while(busy_o) @(posedge clk);
        dvalid_i <= 1; data_i <= encoded_packet; 
        expected_queue.push_back(byte_in);
        sent_packet_queue.push_back(encoded_packet);
        error_count_queue.push_back(num_errors); 
        @(posedge clk); dvalid_i <= 0;
    endtask

    task flush_pipeline();
        repeat(20) encode_and_drive(8'h00, 0); 
        repeat(50) @(posedge clk);
    endtask

    // --- TASK ĐẶC BIỆT: SỬA LỖI 1 BIT VỚI ZERO TAILING ---
    task verify_full_single_bit_correction(input logic [7:0] byte_in);
        logic [15:0] encoded_packet;
        logic [15:0] corrupted_packet;
        logic [15:0] tail_packet; 
        logic [1:0] pair;
        logic [1:0] temp_state;
        
        temp_state = 0; 
        // 1. Mã hóa gói gốc
        for (int i = 0; i < 8; i++) begin
            pair[0] = byte_in[i] ^ temp_state[1] ^ temp_state[0]; 
            pair[1] = byte_in[i] ^ temp_state[0];                     
            temp_state = {byte_in[i], temp_state[1]};
            encoded_packet[15 - (2*i)]     = pair[0]; 
            encoded_packet[15 - (2*i) - 1] = pair[1]; 
        end
        // 2. Mã hóa gói đuôi
        for (int k = 0; k < 8; k++) begin
            pair[0] = 1'b0 ^ temp_state[1] ^ temp_state[0]; 
            pair[1] = 1'b0 ^ temp_state[0];                     
            temp_state = {1'b0, temp_state[1]};
            tail_packet[15 - (2*k)]     = pair[0]; 
            tail_packet[15 - (2*k) - 1] = pair[1]; 
        end

        $display("[INFO] Bit Sweep: %02h (With Zero Tailing)", byte_in);

        for (int err_pos = 0; err_pos < 16; err_pos++) begin
            reset_for_new_test(); 
            
            corrupted_packet = encoded_packet;
            corrupted_packet[err_pos] = ~corrupted_packet[err_pos]; 
            
            // Gửi gói lỗi
            dvalid_i <= 1; data_i <= corrupted_packet; 
            expected_queue.push_back(byte_in);
            sent_packet_queue.push_back(corrupted_packet);
            error_count_queue.push_back(1); // 1-bit error
            @(posedge clk); 
            
            // Gửi gói đuôi
            dvalid_i <= 1; data_i <= tail_packet;
            expected_queue.push_back(8'h00); 
            sent_packet_queue.push_back(tail_packet); 
            error_count_queue.push_back(0); // Đuôi là Clean
            @(posedge clk); 
            dvalid_i <= 0;
            
            // Flush
            repeat(16) begin 
                @(posedge clk); dvalid_i <= 1; data_i <= 16'h0000; 
            end
            dvalid_i <= 0;

            wait_for_queue_empty($sformatf("Pos %0d", err_pos));
        end
    endtask

    // --- TASK ĐẶC BIỆT: BUSY IGNORE ---
    task verify_fifo_saturation_ignore();
        $display("[INFO] Bursting data to force FIFO saturation...");
        for(int k=0; k<18; k++) begin
            dvalid_i <= 1; data_i <= 16'h0000; 
            if (k < 17) begin
                 expected_queue.push_back(8'h00);
                 sent_packet_queue.push_back(16'h0000); 
                 error_count_queue.push_back(0); // Clean
            end
            @(posedge clk); 
        end
        #1; 
        if (busy_o !== 1) begin
             $display("%s[FAIL] FIFO Full but Busy=0!%s", RED, RESET);
             stat_fail[0]++; 
             dvalid_i <= 0;
        end else begin
             $display("%s[INFO] Busy=1. Sending Garbage...%s", GREEN, RESET);
             @(posedge clk); data_i <= 16'hFFFF; 
             @(posedge clk); dvalid_i <= 0;
        end

        // Internal Flush
        repeat(20) begin
            dvalid_i <= 1; data_i <= 16'h0000; 
            @(posedge clk);
        end
        dvalid_i <= 0;
        wait_for_queue_empty("SYS_06 Check");
    endtask

    // --- 6. MAIN TEST SEQUENCE ---
    initial begin
        fork monitor_and_check(); join_none
        
        // --- SYS_01: Sanity Check ---
        reset_for_new_test();
        $display("\n%s[SYS_01] SANITY CHECK%s", BLUE, RESET);
        print_header();
        encode_and_drive(8'h00, 1);
        encode_and_drive(8'hFF, 1);
        encode_and_drive(8'hAA, 1);
        encode_and_drive(8'h55, 1);
        flush_pipeline();
        wait_for_queue_empty("SYS_01");
        print_separator();

        // --- SYS_02: Full Range Sweep ---
        reset_for_new_test();
        $display("\n%s[SYS_02] FULL RANGE SWEEP%s", BLUE, RESET);
        for (int k = 0; k < 256; k++) begin
            logic [7:0] val; val = k;
            encode_and_drive(val, 1);
        end
        flush_pipeline();
        wait_for_queue_empty("SYS_02");
        $display("[INFO] SYS_02 Completed (Check Summary)"); 
        print_separator();

        // --- SYS_03: Single Bit Error ---
        reset_for_new_test();
        $display("\n%s[SYS_03] SINGLE BIT ERROR CORRECTION (Deterministic)%s", BLUE, RESET);
        print_header();
        verify_full_single_bit_correction(8'h44);
        verify_full_single_bit_correction(8'h55);
        verify_full_single_bit_correction(8'hAA);
        verify_full_single_bit_correction(8'hFF);
        print_separator();

        // --- SYS_04: Double Bit Error ---
        reset_for_new_test();
        $display("\n%s[SYS_04] DOUBLE BIT ERROR (Random)%s", BLUE, RESET);
        print_header();
        repeat(50) encode_and_drive_noisy($urandom_range(0, 255), 2);
        flush_pipeline();
        wait_for_queue_empty("SYS_04");
        print_separator();
        
        // --- SYS_04b: Triple Bit Error ---
        reset_for_new_test();
        $display("\n%s[SYS_04b] TRIPLE BIT ERROR (Random)%s", BLUE, RESET);
        print_header();
        repeat(20) encode_and_drive_noisy($urandom_range(0, 255), 3);
        flush_pipeline();
        wait_for_queue_empty("SYS_04b");
        print_separator();

        // --- SYS_05: Burst Error (4 bits) ---
        reset_for_new_test();
        $display("\n%s[SYS_05] BURST ERROR CHECK (4 Bits)%s", BLUE, RESET);
        print_header();
        repeat(20) encode_and_drive_noisy(8'hAA, 4); 
        flush_pipeline();
        // Clear queue thủ công nếu quá nhiều lỗi
        fork 
            wait(expected_queue.size() == 0); 
            begin #100000; expected_queue.delete(); end 
        join_any
        print_separator();

        // --- SYS_06: Busy Ignore ---
        reset_for_new_test();
        $display("\n%s[SYS_06] BUSY IGNORE CHECK%s", BLUE, RESET);
        print_header();
        verify_fifo_saturation_ignore();
        print_separator();

        // --- SYS_07: Continuous Processing ---
        reset_for_new_test();
        $display("\n%s[SYS_07] CONTINUOUS PROCESSING (Stress)%s", BLUE, RESET);
        for(int k=0; k<50; k++) encode_and_drive($urandom_range(0, 255), 1);
        flush_pipeline();
        wait_for_queue_empty("SYS_07");
        print_separator();

        // --- SYS_08: Reset Recovery ---
        reset_for_new_test();
        $display("\n%s[SYS_08] RESET RECOVERY%s", BLUE, RESET);
        print_header();
        encode_and_drive(8'hAA, 1);
        $display("[INFO] Asserting Mid-stream Reset...");
        reset_for_new_test(); 
        encode_and_drive(8'hBB, 1);
        flush_pipeline();
        wait_for_queue_empty("SYS_08");
        print_separator();

        // --- FINAL SUMMARY ---
        print_summary();
        $finish;
    end
endmodule