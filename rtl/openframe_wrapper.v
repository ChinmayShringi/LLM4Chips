// OpenFrame Wrapper for Microwatt CPU
// Maps Microwatt signals to OpenFrame 44 GPIO pins

module user_project_wrapper (
    // Power pins (analog + digital)
    inout vccd1,
    inout vssd1,
    inout vccd2,
    inout vssd2,
    inout vdda1,
    inout vssa1,
    inout vdda2,
    inout vssa2,
    
    // Wishbone bus (from management SoC)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
    
    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,
    
    // IOs (44 pins: 19 left + 19 right + 6 bottom)
    input  [43:0] io_in,
    output [43:0] io_out,
    output [43:0] io_oeb,  // Output enable (0=output, 1=input)
    
    // IRQ
    output [2:0] irq
);

    // Wishbone stub (not used for now)
    assign wbs_ack_o = 1'b0;
    assign wbs_dat_o = 32'b0;
    assign irq = 3'b0;
    assign la_data_out = 128'b0;

    // GPIO Pin Mapping:
    // io_in[0]     -> UART RX
    // io_out[0]    -> UART TX
    // io_in[1]     -> JTAG TCK
    // io_in[2]     -> JTAG TMS
    // io_in[3]     -> JTAG TDI
    // io_in[4]     -> JTAG TRST
    // io_out[1]    -> JTAG TDO
    // io_in[5]     -> SPI Flash SDAT[0] (MISO)
    // io_out[2]    -> SPI Flash CS_N
    // io_out[3]    -> SPI Flash CLK
    // io_out[4]    -> SPI Flash SDAT[0] (MOSI)
    // io_in[37:6]  -> GPIO In [31:0]
    // io_out[37:6] -> GPIO Out [31:0]
    
    // Microwatt signals
    wire uart_rxd;
    wire uart_txd;
    wire [31:0] gpio_in_mw;
    wire [31:0] gpio_out_mw;
    wire [31:0] gpio_dir_mw;
    wire jtag_tck;
    wire jtag_tms;
    wire jtag_tdi;
    wire jtag_trst;
    wire jtag_tdo;
    wire spi_cs_n;
    wire spi_clk;
    wire [3:0] spi_sdat_i;
    wire [3:0] spi_sdat_o;
    wire [3:0] spi_sdat_oe;
    
    // Map OpenFrame IOs to Microwatt signals
    assign uart_rxd = io_in[0];
    assign jtag_tck = io_in[1];
    assign jtag_tms = io_in[2];
    assign jtag_tdi = io_in[3];
    assign jtag_trst = io_in[4];
    assign spi_sdat_i[0] = io_in[5];
    assign spi_sdat_i[3:1] = 3'b0;
    
    // GPIO inputs (32 bits from io_in[37:6])
    assign gpio_in_mw = io_in[37:6];
    
    // Outputs
    assign io_out[0] = uart_txd;
    assign io_out[1] = jtag_tdo;
    assign io_out[2] = spi_cs_n;
    assign io_out[3] = spi_clk;
    assign io_out[4] = spi_sdat_o[0];
    assign io_out[5] = 1'b0;  // Unused
    
    // GPIO outputs (32 bits to io_out[37:6])
    assign io_out[37:6] = gpio_out_mw;
    
    // Remaining outputs (io_out[43:38])
    assign io_out[43:38] = 6'b0;
    
    // Output enables
    // 0 = output enabled, 1 = input (tri-state)
    assign io_oeb[0] = 1'b1;    // UART RX (input)
    assign io_oeb[1] = 1'b0;    // JTAG TDO (output)
    assign io_oeb[2] = 1'b0;    // SPI CS (output)
    assign io_oeb[3] = 1'b0;    // SPI CLK (output)
    assign io_oeb[4] = 1'b0;    // SPI MOSI (output)
    assign io_oeb[5] = 1'b1;    // SPI MISO (input)
    assign io_oeb[43:6] = ~gpio_dir_mw[37:0];  // GPIO direction control
    
    // Simplebus signals (tied off for now)
    wire [7:0] simplebus_in = 8'b0;
    wire simplebus_parity_in = 1'b0;
    wire simplebus_irq = 1'b0;
    wire [7:0] simplebus_out;
    wire simplebus_parity_out;
    wire simplebus_enabled;
    wire simplebus_clk;
    
    // Instantiate Microwatt CPU
    toplevel microwatt_cpu (
        // Clock and Reset
        .ext_clk(wb_clk_i),
        .ext_rst(~wb_rst_i),  // Active low reset for Microwatt
        .alt_reset(1'b1),
        
        // UART
        .uart0_rxd(uart_rxd),
        .uart0_txd(uart_txd),
        
        // SPI Flash
        .spi_flash_cs_n(spi_cs_n),
        .spi_flash_clk(spi_clk),
        .spi_flash_sdat_i(spi_sdat_i),
        .spi_flash_sdat_o(spi_sdat_o),
        .spi_flash_sdat_oe(spi_sdat_oe),
        
        // GPIO
        .gpio_in(gpio_in_mw),
        .gpio_out(gpio_out_mw),
        .gpio_dir(gpio_dir_mw),
        
        // JTAG
        .jtag_tck(jtag_tck),
        .jtag_tms(jtag_tms),
        .jtag_tdi(jtag_tdi),
        .jtag_trst(jtag_trst),
        .jtag_tdo(jtag_tdo),
        
        // Simplebus (tied off)
        .simplebus_bus_in(simplebus_in),
        .simplebus_parity_in(simplebus_parity_in),
        .simplebus_irq(simplebus_irq),
        .simplebus_bus_out(simplebus_out),
        .simplebus_parity_out(simplebus_parity_out),
        .simplebus_enabled(simplebus_enabled),
        .simplebus_clk(simplebus_clk)
    );

endmodule

