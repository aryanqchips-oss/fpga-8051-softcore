`timescale 1ns / 1ps

// Step 1 integration wrapper for the R8051 core.
// This module is intentionally separate from the existing UART memory_controller.
// Program memory is 4 KiB; instruction addresses outside that range return NOP.
// Keep the CPU disabled while programming BRAM through prog_we/prog_addr/prog_data.
module r8051_memory_subsystem (
    input  wire        clk,
    input  wire        rst,
    input  wire        cpu_en,
    input  wire        cpu_restart,

    // Host/programmer write port (connect to the UART loader in a later step)
    input  wire        prog_we,
    input  wire [11:0] prog_addr,
    input  wire [7:0]  prog_data,

    // Observable 8051 ports for board-level integration
    output wire [7:0]  port0,
    output wire [7:0]  port1,
    output wire [7:0]  port2,
    output wire [7:0]  port3
);

    // ---------------- Program memory: 4 KiB ----------------
    reg [7:0] program_mem [0:4095];
    reg [7:0] rom_byte;
    reg       rom_vld;
    wire      rom_en;
    wire [15:0] rom_addr;

    // Synchronous instruction fetch. The valid pulse is aligned with the
    // registered byte and follows the handshake expected by R8051.
    always @(posedge clk) begin
        if (prog_we)
            program_mem[prog_addr] <= prog_data;

        if (rom_en) begin
            if (rom_addr[15:12] == 4'b0000)
                rom_byte <= program_mem[rom_addr[11:0]];
            else
                rom_byte <= 8'h00; // NOP outside implemented 4 KiB code space
        end
        rom_vld <= rom_en;
    end

    // ---------------- R8051 data-memory interface ----------------
    wire ram_rd_en_data;
    wire ram_rd_en_sfr;
    wire ram_rd_en_xdata;
    wire [15:0] ram_rd_addr;
    reg [7:0] ram_rd_byte;
    reg       ram_rd_vld;

    wire ram_wr_en_data;
    wire ram_wr_en_sfr;
    wire ram_wr_en_xdata;
    wire [15:0] ram_wr_addr;
    wire [7:0] ram_wr_byte;

    // 8051 internal RAM: 128 bytes (00h-7Fh).
    reg [7:0] idata [0:127];

    // Minimal external SFR bank for addresses 80h-FFh.
    // The R8051 core handles ACC, PSW, DPTR, SP and B internally.
    reg [7:0] sfr [0:127];

    // A small XDATA space is provided for MOVX instructions.
    // Only the first 4 KiB are implemented; upper addresses read as 00h.
    reg [7:0] xdata_mem [0:4095];

    integer i;
    initial begin
        rom_byte = 8'h00;
        rom_vld = 1'b0;
        ram_rd_byte = 8'h00;
        ram_rd_vld = 1'b0;
        for (i = 0; i < 128; i = i + 1) begin
            idata[i] = 8'h00;
            sfr[i] = 8'h00;
        end
        for (i = 0; i < 4096; i = i + 1)
            xdata_mem[i] = 8'h00;
        // 8051 quasi-bidirectional ports power up high.
        sfr[7'h00] = 8'hFF; // P0 at 80h
        sfr[7'h10] = 8'hFF; // P1 at 90h
        sfr[7'h20] = 8'hFF; // P2 at A0h
        sfr[7'h30] = 8'hFF; // P3 at B0h
    end

    assign port0 = sfr[7'h00];
    assign port1 = sfr[7'h10];
    assign port2 = sfr[7'h20];
    assign port3 = sfr[7'h30];

    // Synchronous read response. Exactly one request class is expected from
    // this core per transaction; priority makes the mux deterministic.
    always @(posedge clk) begin
        ram_rd_vld <= 1'b0;

        if (ram_rd_en_data) begin
            ram_rd_byte <= idata[ram_rd_addr[6:0]];
            ram_rd_vld <= 1'b1;
        end else if (ram_rd_en_sfr) begin
            ram_rd_byte <= sfr[ram_rd_addr[6:0]];
            ram_rd_vld <= 1'b1;
        end else if (ram_rd_en_xdata) begin
            if (ram_rd_addr[15:12] == 4'b0000)
                ram_rd_byte <= xdata_mem[ram_rd_addr[11:0]];
            else
                ram_rd_byte <= 8'h00;
            ram_rd_vld <= 1'b1;
        end

        if (ram_wr_en_data)
            idata[ram_wr_addr[6:0]] <= ram_wr_byte;

        if (ram_wr_en_sfr)
            sfr[ram_wr_addr[6:0]] <= ram_wr_byte;

        if (ram_wr_en_xdata && ram_wr_addr[15:12] == 4'b0000)
            xdata_mem[ram_wr_addr[11:0]] <= ram_wr_byte;
    end

    // ---------------- CPU core ----------------
    r8051 u_cpu (
        .clk(clk),
        .rst(rst),
        .cpu_en(cpu_en),
        .cpu_restart(cpu_restart),

        .rom_en(rom_en),
        .rom_addr(rom_addr),
        .rom_byte(rom_byte),
        .rom_vld(rom_vld),

        .ram_rd_en_data(ram_rd_en_data),
        .ram_rd_en_sfr(ram_rd_en_sfr),
        .ram_rd_en_xdata(ram_rd_en_xdata),
        .ram_rd_addr(ram_rd_addr),
        .ram_rd_byte(ram_rd_byte),
        .ram_rd_vld(ram_rd_vld),

        .ram_wr_en_data(ram_wr_en_data),
        .ram_wr_en_sfr(ram_wr_en_sfr),
        .ram_wr_en_xdata(ram_wr_en_xdata),
        .ram_wr_addr(ram_wr_addr),
        .ram_wr_byte(ram_wr_byte)
    );

endmodule
