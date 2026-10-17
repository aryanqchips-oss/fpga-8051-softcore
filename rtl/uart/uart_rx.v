`timescale 1ns / 1ps
module uart_rx #(parameter CLK_HZ=100000000, parameter BAUD=115200)(
 input wire clk, input wire rst, input wire rx,
 output reg [7:0] rx_data, output reg rx_done
);
 localparam integer CPB=CLK_HZ/BAUD;
 localparam integer HALF=CPB/2;
 localparam [1:0] IDLE=0, START=1, DATA=2, STOP=3;
 reg [1:0] state;
 integer count;
 reg [2:0] bit_index;
 reg [7:0] shift;
 reg rx_meta, rx_sync;
 always @(posedge clk) begin
  if(rst) begin rx_meta<=1'b1; rx_sync<=1'b1; end
  else begin rx_meta<=rx; rx_sync<=rx_meta; end
 end
 always @(posedge clk) begin
  if(rst) begin
   state<=IDLE; count<=0; bit_index<=0; shift<=0; rx_data<=0; rx_done<=0;
  end else begin
   rx_done<=0;
   case(state)
    IDLE: begin
     count<=0; bit_index<=0;
     if(!rx_sync) begin count<=0; state<=START; end
    end
    START: begin
     if(count==HALF-1) begin
      count<=0;
      if(!rx_sync) state<=DATA; else state<=IDLE;
     end else count<=count+1;
    end
    DATA: begin
     if(count==CPB-1) begin
      count<=0; shift[bit_index]<=rx_sync;
      if(bit_index==7) begin bit_index<=0; state<=STOP; end
      else bit_index<=bit_index+1'b1;
     end else count<=count+1;
    end
    STOP: begin
     if(count==CPB-1) begin
      count<=0;
      if(rx_sync) begin rx_data<=shift; rx_done<=1'b1; end
      state<=IDLE;
     end else count<=count+1;
    end
    default: state<=IDLE;
   endcase
  end
 end
endmodule
