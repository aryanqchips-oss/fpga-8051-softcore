
`timescale 1ns / 1ps

module memory_controller #(
    parameter CLK_HZ = 100000000,
    parameter BAUD   = 57600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       usb_uart_rxd,
    output wire       usb_uart_txd,
    output reg [7:0]  led
);

    // UART receiver
    wire [7:0] rx_data;
    wire       rx_done;

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(BAUD)
    ) u_rx (
        .clk(clk),
        .rst(rst),
        .rx(usb_uart_rxd),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // UART transmitter
    reg  [7:0] tx_data;
    reg        tx_start;
    wire       tx_busy;

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(BAUD)
    ) u_tx (
        .clk(clk),
        .rst(rst),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(usb_uart_txd),
        .tx_busy(tx_busy)
    );

    // BRAM interface
    reg        prog_we;
    reg [11:0] prog_addr;
    reg [7:0]  prog_data;

    reg [11:0] cpu_addr;
    wire [7:0] cpu_data;

    program_bram #(
        .ADDR_WIDTH(12),
        .DATA_WIDTH(8)
    ) u_bram (
        .clk(clk),
        .prog_we(prog_we),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .cpu_addr(cpu_addr),
        .cpu_data(cpu_data)
    );

    // Controller states
    localparam IDLE       = 4'd0;
    localparam W_ADDR_HI  = 4'd1;
    localparam W_ADDR_LO  = 4'd2;
    localparam W_DATA     = 4'd3;
    localparam R_ADDR_HI  = 4'd4;
    localparam R_ADDR_LO  = 4'd5;
    localparam R_WAIT1    = 4'd6;
    localparam R_WAIT2    = 4'd7;
    localparam TX_START_S = 4'd8;
    localparam TX_WAIT_S  = 4'd9;

    reg [3:0] state;
    reg [11:0] address_latch;
    reg [7:0] response_byte;

    // Return here after a response has finished transmitting.
    reg [3:0] return_state;
    reg tx_seen_busy;

    always @(posedge clk) begin
        if (rst) begin
        tx_seen_busy <= 1'b0;
            state         <= IDLE;
            address_latch <= 12'd0;
            prog_we       <= 1'b0;
            prog_addr     <= 12'd0;
            prog_data     <= 8'd0;
            cpu_addr      <= 12'd0;
            tx_data       <= 8'd0;
            tx_start      <= 1'b0;
            response_byte <= 8'd0;
            return_state  <= IDLE;
            led           <= 8'd0;
        end else begin
            // Default: all write/start signals are one-cycle pulses.
            prog_we  <= 1'b0;
            tx_start <= 1'b0;

          if (rx_done) begin
    led <= rx_data;
    $display("FPGA RX: byte=%02h time=%0t", rx_data, $time);
end

            case (state)

                IDLE: begin
                    if (rx_done) begin
                        if (rx_data == 8'h57) begin
                            // 'W': write memory
                            state <= W_ADDR_HI;
                        end else if (rx_data == 8'h52) begin
                            // 'R': read memory
                            state <= R_ADDR_HI;
                        end
                    end
                end

                W_ADDR_HI: begin
                    if (rx_done) begin
                        address_latch[11:8] <= rx_data[3:0];
                        state <= W_ADDR_LO;
                    end
                end

                W_ADDR_LO: begin
                    if (rx_done) begin
                        address_latch[7:0] <= rx_data;
                        state <= W_DATA;
                    end
                end

                W_DATA: begin
                    if (rx_done) begin
                        prog_addr <= {address_latch[11:8], address_latch[7:0]};
                        prog_data <= rx_data;
                        prog_we   <= 1'b1;

                        // ACK is sent after the write pulse.
                        response_byte <= 8'h06;
                        return_state  <= IDLE;
                        state         <= TX_START_S;
                    end
                end

                R_ADDR_HI: begin
                    if (rx_done) begin
                        address_latch[11:8] <= rx_data[3:0];
                        state <= R_ADDR_LO;
                    end
                end

                R_ADDR_LO: begin
                    if (rx_done) begin
                        address_latch[7:0] <= rx_data;
                        cpu_addr <= {address_latch[11:8], rx_data};
                        state <= R_WAIT1;
                    end
                end

                R_WAIT1: begin
                    // Allow the synchronous BRAM read to complete.
                    state <= R_WAIT2;
                end

                R_WAIT2: begin
                    response_byte <= cpu_data;
                    return_state  <= IDLE;
                    state         <= TX_START_S;
                end

               TX_START_S: begin
                    if (!tx_busy) begin
                        tx_data      <= response_byte;
                        tx_start     <= 1'b1;
                        tx_seen_busy <= 1'b0;
                        state        <= TX_WAIT_S;
                    end
                end
                
                TX_WAIT_S: begin
                    if (tx_busy)
                        tx_seen_busy <= 1'b1;
                
                    if (tx_seen_busy && !tx_busy) begin
                        tx_seen_busy <= 1'b0;
                        state <= return_state;
                    end
               end
            endcase
        end
    end
   
endmodule

