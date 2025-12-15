module pmu #(
    parameter TBL      = 15,       // Traceback Length
    parameter PM_WIDTH = 8         // Path Metric width
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_i,         // Write enable from PISO/ACSU valid

    // From ACSU: New decisions and PMs
    input  wire [3:0]             dec_bits_i,
    input  wire [PM_WIDTH-1:0]    pm_new_s0_i,
    input  wire [PM_WIDTH-1:0]    pm_new_s1_i,
    input  wire [PM_WIDTH-1:0]    pm_new_s2_i,
    input  wire [PM_WIDTH-1:0]    pm_new_s3_i,

    // From TBU: Read address
    input  wire [$clog2(TBL)-1:0] read_addr_i,

    // To ACSU & TBU: Current PMs
    output reg  [PM_WIDTH-1:0]    pm_current_s0_o,
    output reg  [PM_WIDTH-1:0]    pm_current_s1_o,
    output reg  [PM_WIDTH-1:0]    pm_current_s2_o,
    output reg  [PM_WIDTH-1:0]    pm_current_s3_o,

    // To TBU: Read data (decision bits at addr)
    output wire [3:0]             read_data_o
);

    // Decision memory: Array as shift register (0: oldest, TBL-1: newest)
    reg [3:0] dec_mem [0:TBL-1];

    // Combinational read for zero latency
    assign read_data_o = dec_mem[read_addr_i];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset PMs to 0 (or set S0=0, others=max for initial bias, but spec uses 0)
            pm_current_s0_o <= {PM_WIDTH{1'b0}};
            pm_current_s1_o <= {PM_WIDTH{1'b0}};
            pm_current_s2_o <= {PM_WIDTH{1'b0}};
            pm_current_s3_o <= {PM_WIDTH{1'b0}};

            // Clear decision memory
            for (i = 0; i < TBL; i = i + 1) begin
                dec_mem[i] <= 4'b0000;
            end
        end else if (valid_i) begin
            // Update current PMs from new ones
            pm_current_s0_o <= pm_new_s0_i;
            pm_current_s1_o <= pm_new_s1_i;
            pm_current_s2_o <= pm_new_s2_i;
            pm_current_s3_o <= pm_new_s3_i;

            // Shift decision memory: Make room for new at newest position
            // Shift from newest to oldest: dec_mem[0] (oldest) gets dec_mem[1], ..., dec_mem[13] gets dec_mem[14], dec_mem[14] gets new
            for (i = 0; i < TBL-1; i = i + 1) begin
                dec_mem[i] <= dec_mem[i+1];
            end
            dec_mem[TBL-1] <= dec_bits_i;  // Insert newest decision at highest index
        end
    end

endmodule