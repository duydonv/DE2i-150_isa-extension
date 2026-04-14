module de2i_150_pico_blink (
    input  wire       clock_50,
    input  wire       reset_n,
    output wire       uart_tx,
    input  wire       uart_rx,
    output wire [7:0] lcd_data,
    output wire       lcd_en,
    output wire       lcd_rw,
    output wire       lcd_rs,
    output wire       lcd_on,
    output wire [17:0] ledr,
    output wire [1:0] ledg
);
    localparam [31:0] RAM_SIZE_BYTES = 32'h0000_8000;
    localparam [31:0] STACK_TOP      = 32'h0000_8000;
    localparam [31:0] UART_DIV_ADDR  = 32'h0200_0004;
    localparam [31:0] UART_DAT_ADDR  = 32'h0200_0008;
    localparam [31:0] LCD_CMD_ADDR   = 32'h0200_0010;
    localparam [31:0] LCD_DAT_ADDR   = 32'h0200_0014;
    localparam [31:0] LCD_STS_ADDR   = 32'h0200_0018;
    localparam [31:0] LED_ADDR       = 32'h0300_0000;
    localparam integer MEM_WORDS     = 8192;

    wire clk = clock_50;

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire        trap;

    wire        valid_ram = mem_valid && (mem_addr < RAM_SIZE_BYTES);
    wire [12:0] word_addr = mem_addr[14:2];

    reg  [1:0]  reset_sync;
    wire        cpu_resetn = reset_sync[1];

    reg         ram_ready;
    reg [31:0]  ram_rdata;
    reg [7:0]   led_reg;
    reg [25:0]  hb_div;
    reg [1:0]   uart_rx_sync;
    reg [31:0]  last_instr_addr;
    reg [31:0]  last_instr_data;

    // Quartus Std on Cyclone IV is more reliable with byte lanes split into
    // independent 8-bit memories than with one 32-bit preinitialized RAM.
    (* ramstyle = "M9K" *) reg [7:0] memory0 [0:MEM_WORDS-1];
    (* ramstyle = "M9K" *) reg [7:0] memory1 [0:MEM_WORDS-1];
    (* ramstyle = "M9K" *) reg [7:0] memory2 [0:MEM_WORDS-1];
    (* ramstyle = "M9K" *) reg [7:0] memory3 [0:MEM_WORDS-1];

    initial begin
        $readmemh("firmware/firmware_byte0.hex", memory0);
        $readmemh("firmware/firmware_byte1.hex", memory1);
        $readmemh("firmware/firmware_byte2.hex", memory2);
        $readmemh("firmware/firmware_byte3.hex", memory3);
    end

    wire        uart_div_sel  = mem_valid && (mem_addr == UART_DIV_ADDR);
    wire [31:0] uart_div_rdata;

    wire        uart_dat_sel  = mem_valid && (mem_addr == UART_DAT_ADDR);
    wire [31:0] uart_dat_rdata;
    wire        uart_dat_wait;

    wire        lcd_cmd_sel   = mem_valid && (mem_addr == LCD_CMD_ADDR);
    wire        lcd_dat_sel   = mem_valid && (mem_addr == LCD_DAT_ADDR);
    wire        lcd_sts_sel   = mem_valid && (mem_addr == LCD_STS_ADDR);
    wire        lcd_busy;
    wire        lcd_cmd_wr    = lcd_cmd_sel && |mem_wstrb && !lcd_busy;
    wire        lcd_dat_wr    = lcd_dat_sel && |mem_wstrb && !lcd_busy;

    wire        led_sel       = mem_valid && (mem_addr == LED_ADDR);
    wire        invalid_sel   = mem_valid && !valid_ram && !uart_div_sel && !uart_dat_sel &&
                                !lcd_cmd_sel && !lcd_dat_sel && !lcd_sts_sel && !led_sel;

    picorv32 #(
        .ENABLE_PCPI      (1'b0),
        .ENABLE_MUL       (1'b0),
        .ENABLE_FAST_MUL  (1'b0),
        .ENABLE_DIV       (1'b0),
        .ENABLE_IRQ       (1'b0),
        .LATCHED_MEM_RDATA(1'b0),
        .PROGADDR_RESET   (32'h0000_0000),
        .STACKADDR        (STACK_TOP)
    ) cpu (
        .clk        (clk),
        .resetn     (cpu_resetn),
        .trap       (trap),
        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),
        .pcpi_wr    (1'b0),
        .pcpi_rd    (32'h0000_0000),
        .pcpi_wait  (1'b0),
        .pcpi_ready (1'b0),
        .irq        (32'h0000_0000),
        .eoi        (),
        .trace_valid(),
        .trace_data ()
    );

    simpleuart uart (
        .clk         (clk),
        .resetn      (cpu_resetn),
        .ser_tx      (uart_tx),
        .ser_rx      (uart_rx_sync[1]),
        .reg_div_we  (uart_div_sel ? mem_wstrb : 4'b0000),
        .reg_div_di  (mem_wdata),
        .reg_div_do  (uart_div_rdata),
        .reg_dat_we  (uart_dat_sel ? mem_wstrb[0] : 1'b0),
        .reg_dat_re  (uart_dat_sel && !mem_wstrb),
        .reg_dat_di  (mem_wdata),
        .reg_dat_do  (uart_dat_rdata),
        .reg_dat_wait(uart_dat_wait)
    );

    lcd_hd44780 #(
        .CLK_HZ(50000000)
    ) lcd (
        .clk      (clk),
        .resetn   (cpu_resetn),
        .cmd_wr   (lcd_cmd_wr),
        .cmd_data (mem_wdata[7:0]),
        .data_wr  (lcd_dat_wr),
        .data_data(mem_wdata[7:0]),
        .busy     (lcd_busy),
        .lcd_data (lcd_data),
        .lcd_en   (lcd_en),
        .lcd_rw   (lcd_rw),
        .lcd_rs   (lcd_rs),
        .lcd_on   (lcd_on)
    );

    always @(posedge clk) begin
        if (valid_ram && !mem_ready) begin
            ram_rdata <= {memory3[word_addr], memory2[word_addr], memory1[word_addr], memory0[word_addr]};
            if (mem_wstrb[0]) memory0[word_addr] <= mem_wdata[7:0];
            if (mem_wstrb[1]) memory1[word_addr] <= mem_wdata[15:8];
            if (mem_wstrb[2]) memory2[word_addr] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory3[word_addr] <= mem_wdata[31:24];
        end
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            reset_sync <= 2'b00;
        end else begin
            reset_sync <= {reset_sync[0], 1'b1};
        end
    end

    always @(posedge clk) begin
        if (!cpu_resetn) begin
            ram_ready <= 1'b0;
            led_reg   <= 8'h00;
            hb_div    <= 26'd0;
            uart_rx_sync <= 2'b11;
            last_instr_addr <= 32'h0000_0000;
            last_instr_data <= 32'h0000_0000;
        end else begin
            ram_ready <= valid_ram && !mem_ready;
            hb_div    <= hb_div + 26'd1;
            uart_rx_sync <= {uart_rx_sync[0], uart_rx};

            if (mem_valid && mem_ready && mem_instr) begin
                last_instr_addr <= mem_addr;
                last_instr_data <= mem_rdata;
            end

            if (led_sel && |mem_wstrb)
                led_reg <= mem_wdata[7:0];
        end
    end

    assign mem_ready =
        ram_ready ||
        uart_div_sel ||
        (uart_dat_sel && !uart_dat_wait) ||
        lcd_sts_sel ||
        ((lcd_cmd_sel || lcd_dat_sel) && !lcd_busy) ||
        led_sel ||
        invalid_sel;

    assign mem_rdata =
        ram_ready ? ram_rdata :
        uart_div_sel ? uart_div_rdata :
        uart_dat_sel ? uart_dat_rdata :
        lcd_sts_sel  ? {31'd0, lcd_busy} :
        led_sel   ? {24'h000000, led_reg} :
        32'h0000_0000;

    assign ledr = trap ? {10'b0, last_instr_data[7:0]} : {10'b0, led_reg};
    assign ledg = {trap, hb_div[25]};
endmodule
