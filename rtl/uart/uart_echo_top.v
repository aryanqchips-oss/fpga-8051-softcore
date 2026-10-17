`timescale 1ns / 1ps
module uart_echo_top #(parameter CLK_HZ=100000000, parameter BAUD=115200)(
 input wire clk, input wire rst_btn, input wire usb_uart_rxd,
 output wire usb_uart_txd, output reg [7:0] led
);
 wire [7:0] rx_data;
 wire rx_done, tx_busy;
 reg [7:0] tx_data;
 reg tx_start;
 uart_rx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) u_rx(
  .clk(clk),.rst(rst_btn),.rx(usb_uart_rxd),.rx_data(rx_data),.rx_done(rx_done));
 uart_tx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) u_tx(
  .clk(clk),.rst(rst_btn),.tx_data(tx_data),.tx_start(tx_start),
  .tx(usb_uart_txd),.tx_busy(tx_busy));
 // Initial smoke test: send bytes with a gap; one-byte receive buffer.
 always @(posedge clk) begin
  if(rst_btn) begin tx_data<=0; tx_start<=0; led<=0; end
  else begin
   tx_start<=0;
   if(rx_done) begin
    led<=rx_data;
    if(!tx_busy) begin tx_data<=rx_data; tx_start<=1'b1; end
   end
  end
 end
endmodule
