`include "system_top.v"
`timescale 1ns/1ps

module tb_system_top;

    // --- 1. Signal Declaration ---
    logic        clk;
    logic        rst_n;
    logic        dvalid_i;
    logic [15:0] data_i;
    logic [7:0]  data_o;
    logic        valid_o;
    logic        busy_o;

    // --- 2. Test Parameters ---
    localparam CLK_PERIOD = 10; // 100MHz
    localparam TEST_LEN   = 50; // Số lượng byte test

    // Queue to store Golden Model data for comparison
    logic [7:0] expected_queue [$];

    // Simulated Encoder State
    logic [1:0] encoder_state; 
    
    // --- KHAI BÁO BIẾN CÒN THIẾU ---
    bit first_byte_rcvd; 

    // --- 3. Instantiate DUT (Device Under Test) ---
    system_top u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .dvalid_i(dvalid_i),
        .data_i(data_i),
        .data_o(data_o),
        .valid_o(valid_o),
        .busy_o(busy_o)
    );

    // --- 4. Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --- 5. Encoder Task (Software Encoder Model) ---
    task encode_and_drive(input logic [7:0] byte_in);
        logic [15:0] encoded_packet;
        logic [1:0]  pair;
        logic        bit_in;
        int          i;
        
        for (i = 0; i < 8; i++) begin
            bit_in = byte_in[i]; 
            // g0 = 111, g1 = 101
            pair[0] = bit_in ^ encoder_state[1] ^ encoder_state[0]; 
            pair[1] = bit_in ^ encoder_state[0];                    
            encoder_state = {bit_in, encoder_state[1]};
            
            // MSB first packing
            encoded_packet[15 - (2*i)]     = pair[0]; 
            encoded_packet[15 - (2*i) - 1] = pair[1]; 
        end

        @(posedge clk);

        while(busy_o == 1'b1) begin
            @(posedge clk);
        end

        dvalid_i <= 1'b1;
        data_i <= encoded_packet;
        expected_queue.push_back(byte_in);

        @(posedge clk);
        dvalid_i <= 1'b0;

        /*if (busy_o) wait(busy_o == 0);

        @(posedge clk);
        dvalid_i <= 1'b1;
        data_i   <= encoded_packet;
        expected_queue.push_back(byte_in);

        @(posedge clk);
        dvalid_i <= 1'b0;*/ 
    endtask

    // --- 5b. Encoder Task WITH NOISE INJECTION ---
    // num_errors: Số lượng bit muốn cố tình làm sai trong gói 16-bit
    task encode_and_drive_noisy(input logic [7:0] byte_in, input int num_errors);
        logic [15:0] encoded_packet;
        logic [1:0]  pair;
        logic        bit_in;
        int          i;
        int          err_pos;
        
        // 1. Mã hóa chuẩn (Giống hệt task cũ)
        for (i = 0; i < 8; i++) begin
            bit_in = byte_in[i]; 
            pair[0] = bit_in ^ encoder_state[1] ^ encoder_state[0]; 
            pair[1] = bit_in ^ encoder_state[0];                    
            encoder_state = {bit_in, encoder_state[1]};
            
            encoded_packet[15 - (2*i)]     = pair[0]; 
            encoded_packet[15 - (2*i) - 1] = pair[1]; 
        end

        // 2. THÊM NHIỄU (Inject Errors)
        // Chọn ngẫu nhiên vị trí bit và đảo ngược nó (0->1, 1->0)
        repeat(num_errors) begin
            err_pos = $urandom_range(0, 15); // Chọn vị trí từ 0 đến 15
            encoded_packet[err_pos] = ~encoded_packet[err_pos]; // Đảo bit (Gây lỗi)
            // Uncomment dòng dưới nếu muốn soi kỹ xem lỗi ở đâu
            $display("[NOISE] Injecting error at bit index %0d for Data %h", err_pos, byte_in);
        end

        // 3. Gửi dữ liệu (Flow Control Robust)
        @(posedge clk);
        while (busy_o == 1'b1) begin
            @(posedge clk);
        end

        dvalid_i <= 1'b1;
        data_i   <= encoded_packet; // Gửi gói tin ĐÃ BỊ LỖI
        expected_queue.push_back(byte_in); // Vẫn kỳ vọng ra đúng dữ liệu gốc

        @(posedge clk);
        dvalid_i <= 1'b0; 
    endtask

    // --- 6. Main Test Process (Driver) ---
    initial begin
        // Init
        rst_n = 0;
        dvalid_i = 0;
        data_i = 0;
        encoder_state = 2'b00;
        first_byte_rcvd = 0; // Reset cờ
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        $display("------------------------------------------------");
        $display("   TEST 1: STARTING SANITY CHECK FOR VITERBI DECODER");
        $display("------------------------------------------------");

        for (int k = 0; k < TEST_LEN; k++) begin
            logic [7:0] rand_byte;
            rand_byte = $urandom(); 
            encode_and_drive(rand_byte);
            
            if (k % 5 == 0) repeat(3) @(posedge clk); 
        end

        dvalid_i <= 0;
        
        // Timeout
        fork : wait_complete
            wait(expected_queue.size() == 0);
            begin
                #200000; 
                $display("WARNING: Test 1 timed out.");
                disable wait_complete;
            end
        join

        repeat(50) @(posedge clk);

        $display("------------------------------------------------");
        $display("   TEST 2: NOISY CHANNEL (30 Bytes - 1 Bit Error/Packet)");
        $display("------------------------------------------------");
        // Viterbi K=3 thường sửa tốt 1 bit lỗi trong 1 gói 16 bit
        for(int k = 0; k < 30; k++) begin
            logic [7:0] rand_byte;
            rand_byte = $urandom();
            // gọi task nhiễu, tham số 1 nghĩa là đảo 1 bit ngẫu nhiên
            encode_and_drive_noisy(rand_byte, 1);
            if(k % 5 == 0) repeat(3) @(posedge clk);
        end


        $display("------------------------------------------------");
        $display("   TEST FINISHED - CHECK LOGS ABOVE");
        $display("------------------------------------------------");
        $finish;
    end

    // --- 7. Monitor & Checker Process (ĐÃ SỬA LOGIC) ---
    initial begin
        logic [7:0] exp_data;
        
        forever begin
            @(posedge clk);
            if (valid_o) begin
                // --- Logic xử lý chính xác ---
                if (!first_byte_rcvd) begin
                    first_byte_rcvd = 1;
                    // Check xem có phải byte rác không
                    if (data_o == 8'h00 && expected_queue.size() > 0 && expected_queue[0] != 8'h00) begin
                        $display("[INFO] Skipping Warm-up Byte: %h", data_o);
                        // QUAN TRỌNG: Không làm gì cả, vòng lặp forever sẽ quay lại đợi valid tiếp theo
                    end else begin
                        // Nếu không phải rác (hoặc rác trùng hợp là data đúng), thì check bình thường
                        if (expected_queue.size() > 0) begin
                            exp_data = expected_queue.pop_front();
                            if (data_o === exp_data)
                                $display("[TIME %t] PASS: Received %h | Expected %h", $time, data_o, exp_data);
                            else
                                $error("[TIME %t] FAIL: Received %h | Expected %h", $time, data_o, exp_data);
                        end
                    end
                end else begin
                    // --- Từ byte thứ 2 trở đi ---
                    if (expected_queue.size() == 0) begin
                        $error("ERROR: Received data %h but queue is empty!", data_o);
                    end else begin
                        exp_data = expected_queue.pop_front();
                        if (data_o === exp_data) begin
                            $display("[TIME %t] PASS: Received %h | Expected %h", $time, data_o, exp_data);
                        end else begin
                            $error("[TIME %t] FAIL: Received %h | Expected %h -> MISMATCH!", $time, data_o, exp_data);
                        end
                    end
                end
            end
        end
    end

    // Safety Timeout
    initial begin
        #1000000; 
        $display("FATAL: System watchdog timeout.");
        $finish;
    end

    // Dump wave
    initial begin
        $dumpfile("system.vcd"); // Đổi thành .vcd cho chuẩn
        $dumpvars(0, tb_system_top);
    end

endmodule