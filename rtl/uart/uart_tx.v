`timescale 1ns / 1ps
module uart_tx #(parameter CLK_HZ=100000000, parameter BAUD=115200)(
 input wire clk, input wire rst, input wire [7:0] tx_data,
 input wire tx_start, output reg tx, output reg tx_busy
);
 localparam integer CPB=CLK_HZ/BAUD;
 localparam [1:0] IDLE=0, START=1, DATA=2, STOP=3;
 reg [1:0] state;
 integer count;
 reg [2:0] bit_index;
 reg [7:0] data_latch;
 always @(posedge clk) begin
  if(rst) begin
   state<=IDLE; count<=0; bit_index<=0; data_latch<=0; tx<=1'b1; tx_busy<=1'b0;
  end else begin
   case(state)
    IDLE: begin
     tx<=1'b1; tx_busy<=1'b0; count<=0; bit_index<=0;
     if(tx_start) begin data_latch<=tx_data; tx_busy<=1'b1; tx<=1'b0; state<=START; end
    end
    START: begin
     tx_busy<=1'b1;
     if(count==CPB-1) begin count<=0; tx<=data_latch[0]; bit_index<=0; state<=DATA; end
     else count<=count+1;
    end
    DATA: begin
     tx_busy<=1'b1;
     if(count==CPB-1) begin
      count<=0;
      if(bit_index==7) begin tx<=1'b1; state<=STOP; end
      else begin bit_index<=bit_index+1'b1; tx<=data_latch[bit_index+1'b1]; end
     end else count<=count+1;
    end
    STOP: begin
     tx_busy<=1'b1;
     if(count==CPB-1) begin count<=0; tx<=1'b1; tx_busy<=1'b0; state<=IDLE; end
     else count<=count+1;
    end
    default: begin state<=IDLE; tx<=1'b1; tx_busy<=1'b0; end
   endcase
  end
 end
endmodule
