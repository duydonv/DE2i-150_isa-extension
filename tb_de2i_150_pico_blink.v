`timescale 1ns/1ps

module tb_de2i_150_pico_blink;
    reg clock_50 = 0;
    reg reset_n  = 0;
    reg uart_rx  = 1;

    wire uart_tx;
    wire [7:0] lcd_data;
    wire lcd_en;
    wire lcd_rw;
    wire lcd_rs;
    wire lcd_on;
    wire [17:0] ledr;
    wire [1:0] ledg;

    de2i_150_pico_blink dut (
        .clock_50(clock_50),
        .reset_n (reset_n),
        .uart_tx (uart_tx),
        .uart_rx (uart_rx),
        .lcd_data(lcd_data),
        .lcd_en  (lcd_en),
        .lcd_rw  (lcd_rw),
        .lcd_rs  (lcd_rs),
        .lcd_on  (lcd_on),
        .ledr    (ledr),
        .ledg    (ledg)
    );

    // 50 MHz clock => period 20 ns
    always #10 clock_50 = ~clock_50;

    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rx = 1'b1;
            #(8680);
            uart_rx = 1'b0; // start bit
            #(8680);

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i]; // LSB first
                #(8680);
            end

            uart_rx = 1'b1; // stop bit
            #(8680);
        end
    endtask

    initial begin
        reset_n = 1'b0;
        uart_rx = 1'b1;

        // reset đầu vào
        #200;
        reset_n = 1'b1;

        // chờ LCD init và firmware chạy
        #30000000; // 30 ms

        // giả lập laptop gửi chuỗi "Hello\n"
        uart_send_byte("H");
        uart_send_byte("e");
        uart_send_byte("l");
        uart_send_byte("l");
        uart_send_byte("o");
        uart_send_byte(8'h0A);

        // chờ thêm để xem LED/UART/LCD
        #50000000; // 50 ms

        $stop;
    end
endmodule