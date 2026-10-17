
`timescale 1ns / 1ps

module tb_memory_controller;

    reg clk;
    reg rst;
    reg usb_uart_rxd;
    wire usb_uart_txd;
    wire [7:0] led;

    integer errors;
    reg [7:0] received_byte;

    localparam integer CLK_PERIOD_NS = 1000;
    localparam integer BIT_TIME_NS = 20000;

    memory_controller #(
        .CLK_HZ(1000000),
        .BAUD(50000)
    ) dut (
        .clk(clk),
        .rst(rst),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd),
        .led(led)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD_NS/2) clk = ~clk;

    // Send one 8-N-1 UART byte, least-significant bit first.
    task send_byte;
        input [7:0] value;
        integer i;
        begin
            usb_uart_rxd = 1'b0;
            #(BIT_TIME_NS);

            for (i = 0; i < 8; i = i + 1) begin
                usb_uart_rxd = value[i];
                #(BIT_TIME_NS);
            end

            usb_uart_rxd = 1'b1;
            #(BIT_TIME_NS);
            // Extra idle time between bytes.
            #(BIT_TIME_NS);
        end
    endtask

    // Receive one 8-N-1 UART byte.
    task receive_byte;
        output [7:0] value;
        integer i;
        begin
            value = 8'h00;

            // Wait for the start bit.
            @(negedge usb_uart_txd);
            #(BIT_TIME_NS + BIT_TIME_NS/2);

            for (i = 0; i < 8; i = i + 1) begin
                value[i] = usb_uart_txd;
                #(BIT_TIME_NS);
            end
            $display("UART TX sampled byte = %02h at time %0t",
         value, $time);
            // Sample the stop bit.
            if (usb_uart_txd !== 1'b1) begin
                $display("FAIL: UART stop bit was not high");
                errors = errors + 1;
            end

            #(BIT_TIME_NS);
        end
    endtask

    initial begin
        errors = 0;
        rst = 1'b1;
        usb_uart_rxd = 1'b1;

        repeat (10) @(negedge clk);
        rst = 1'b0;
        repeat (10) @(negedge clk);

        $display("Sending WRITE command...");
        send_byte(8'h57); // W
        send_byte(8'h00); // Address high
        send_byte(8'h00); // Address low
        send_byte(8'h41); // Data A

        receive_byte(received_byte);

        if (received_byte === 8'h06)
            $display("PASS: WRITE acknowledgment received");
        else begin
            $display("FAIL: Expected ACK 06, got %02h",
                     received_byte);
            errors = errors + 1;
        end

        $display("Sending READ command...");
        send_byte(8'h52); // R
        send_byte(8'h00); // Address high
        send_byte(8'h00); // Address low

        receive_byte(received_byte);

        if (received_byte === 8'h41)
            $display("PASS: Read-back returned 41 ('A')");
        else begin
            $display("FAIL: Expected 41, got %02h",
                     received_byte);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL MEMORY CONTROLLER TESTS PASSED");
        else
            $display("TEST FAILED: %0d error(s)", errors);

        $finish;
    end

    initial begin
        // Prevent a broken test from running forever.
        #5000000;
        $display("FAIL: Simulation timeout");
        $finish;
    end

endmodule
