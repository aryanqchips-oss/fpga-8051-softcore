`timescale 1ns / 1ps
module tb_r8051_smoke;
 reg clk,rst; wire rom_en; wire [15:0] rom_addr; reg [7:0] rom_byte; reg rom_vld;
 wire ram_rd_en_data,ram_rd_en_sfr,ram_rd_en_xdata; wire [15:0] ram_rd_addr; reg [7:0] ram_rd_byte; reg ram_rd_vld;
 wire ram_wr_en_data,ram_wr_en_sfr,ram_wr_en_xdata; wire [15:0] ram_wr_addr; wire [7:0] ram_wr_byte;
 reg [7:0] rom [0:65535]; reg [7:0] data_ram [0:127]; integer i;
 initial clk=0; always #5 clk=~clk;
 r8051 dut(.clk(clk),.rst(rst),.cpu_en(1'b1),.cpu_restart(1'b0),.rom_en(rom_en),.rom_addr(rom_addr),.rom_byte(rom_byte),.rom_vld(rom_vld),.ram_rd_en_data(ram_rd_en_data),.ram_rd_en_sfr(ram_rd_en_sfr),.ram_rd_en_xdata(ram_rd_en_xdata),.ram_rd_addr(ram_rd_addr),.ram_rd_byte(ram_rd_byte),.ram_rd_vld(ram_rd_vld),.ram_wr_en_data(ram_wr_en_data),.ram_wr_en_sfr(ram_wr_en_sfr),.ram_wr_en_xdata(ram_wr_en_xdata),.ram_wr_addr(ram_wr_addr),.ram_wr_byte(ram_wr_byte));
 initial begin
  for(i=0;i<65536;i=i+1) rom[i]=8'h00; for(i=0;i<128;i=i+1) data_ram[i]=8'h00;
  // MOV A,#55h; MOV 30h,A; MOV A,#00h; MOV A,30h; SJMP $
  rom[0]=8'h74;rom[1]=8'h55;rom[2]=8'hF5;rom[3]=8'h30;rom[4]=8'h74;rom[5]=8'h00;rom[6]=8'hE5;rom[7]=8'h30;rom[8]=8'h80;rom[9]=8'hFE;
  rom_byte=0;rom_vld=0;ram_rd_byte=0;ram_rd_vld=0;
 end
 always @(posedge clk) begin if(rom_en) rom_byte<=rom[rom_addr]; rom_vld<=rom_en; end
 always @(posedge clk) begin ram_rd_vld<=0; if(ram_wr_en_data) data_ram[ram_wr_addr[6:0]]<=ram_wr_byte; if(ram_rd_en_data) begin ram_rd_byte<=data_ram[ram_rd_addr[6:0]];ram_rd_vld<=1;end end
 initial begin rst=1;repeat(4) @(posedge clk);@(negedge clk);rst=0;repeat(300) @(posedge clk);#1;$display("R8051 SMOKE TEST");$display("Accumulator A = %02h",dut.acc);$display("Internal RAM[30h] = %02h",data_ram[8'h30]);if(data_ram[8'h30]===8'h55 && dut.acc===data_ram[8'h30]) $display("PASS: RAM contents and accumulator match");else $display("FAIL: RAM read-back mismatch");$finish;end
endmodule
