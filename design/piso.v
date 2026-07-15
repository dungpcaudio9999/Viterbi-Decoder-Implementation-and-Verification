module piso (
    input  wire        clk,
    input  wire        rst_n,
    
    // FIFO Interface
    input  wire [15:0] fifo_data_i,  // Data from FIFO
    input  wire        fifo_empty_i, // FIFO empty flag
    output reg         fifo_rd_en_o, // Read command sent to FIFO
    
    // Output to Viterbi Core
    output reg  [1:0]  data_serial_o,
    output reg         valid_serial_o
);

    reg [15:0] shift_reg;
    reg [3:0]  count;
    
    // FSM States
    localparam IDLE      = 2'b00;
    localparam READ_WAIT = 2'b01; 
    localparam SHIFT     = 2'b10;
    
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            shift_reg      <= 16'b0;
            data_serial_o  <= 2'b00;
            valid_serial_o <= 1'b0;
            fifo_rd_en_o   <= 1'b0;
            count          <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid_serial_o <= 1'b0;
                    data_serial_o  <= 2'b00;
                    count          <= 4'd0;
                    
                    if (!fifo_empty_i) begin
                        fifo_rd_en_o <= 1'b1;
                        state        <= READ_WAIT;
                    end else begin
                        fifo_rd_en_o <= 1'b0;
                        state        <= IDLE;
                    end
                end

                READ_WAIT: begin
                    fifo_rd_en_o   <= 1'b0; // Disable read command
                    valid_serial_o <= 1'b1;
                    count          <= 4'd7; 
                    
                    // Fetch data and perform first shift (MSB)
                    data_serial_o  <= fifo_data_i[15:14]; 
                    shift_reg      <= {fifo_data_i[13:0], 2'b00};
                    state          <= SHIFT;
                end

                SHIFT: begin
                    fifo_rd_en_o <= 1'b0; // Ensure read command is always disabled during shift
                    
                    if (count > 0) begin
                        data_serial_o  <= shift_reg[15:14];
                        shift_reg      <= {shift_reg[13:0], 2'b00};
                        valid_serial_o <= 1'b1;
                        count          <= count - 1;
                        state          <= SHIFT;
                    end else begin
                        data_serial_o  <= 2'b00;
                        shift_reg      <= 16'b0;
                        valid_serial_o <= 1'b0;
                        count          <= 4'd0;
                        state          <= IDLE; 
                    end
                end
                
                default: begin
                    state          <= IDLE;
                    fifo_rd_en_o   <= 1'b0;
                    valid_serial_o <= 1'b0;
                    data_serial_o  <= 2'b00;
                    shift_reg      <= 16'b0;
                    count          <= 4'd0;
                end
            endcase
        end
    end
endmodule