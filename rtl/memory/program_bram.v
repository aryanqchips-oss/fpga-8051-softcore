
`timescale 1ns / 1ps

module program_bram #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 8
)(
    input wire                  clk,

    // Programming port: used later by the UART bootloader
    input wire                  prog_we,
    input wire [ADDR_WIDTH-1:0] prog_addr,
    input wire [DATA_WIDTH-1:0] prog_data,

    // CPU read port: used later by the 8051 core
    input wire [ADDR_WIDTH-1:0] cpu_addr,
    output reg [DATA_WIDTH-1:0] cpu_data
);

    // 4096 bytes by default
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Programming writes and CPU reads are synchronous.
    always @(posedge clk) begin
        if (prog_we)
            mem[prog_addr] <= prog_data;

        cpu_data <= mem[cpu_addr];
    end

endmodule
