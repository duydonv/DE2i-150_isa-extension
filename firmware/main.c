#include <stdint.h>

#define CLOCK_HZ     50000000u
#define UART_BAUD    115200u
#define STATUS_PERIOD_LOOPS 1000u
#define RX_IDLE_RESTART_LOOPS 300u
#define LED_REG (*(volatile uint32_t *)0x03000000u)
#define UART_REG_DIV (*(volatile uint32_t *)0x02000004u)
#define UART_REG_DAT (*(volatile uint32_t *)0x02000008u)
#define LCD_REG_CMD  (*(volatile uint32_t *)0x02000010u)
#define LCD_REG_DAT  (*(volatile uint32_t *)0x02000014u)
#define LCD_REG_STS  (*(volatile uint32_t *)0x02000018u)

static void uart_putc(char ch)
{
    UART_REG_DAT = (uint8_t)ch;
}

static void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}

static void uart_put_u32(uint32_t value)
{
    static const uint32_t divisors[] = {
        1000000000u, 100000000u, 10000000u, 1000000u, 100000u,
        10000u, 1000u, 100u, 10u, 1u
    };
    uint32_t i;
    uint32_t started = 0u;

    if (value == 0) {
        uart_putc('0');
        return;
    }

    for (i = 0; i < 10u; i++) {
        uint8_t digit = 0u;
        while (value >= divisors[i]) {
            value -= divisors[i];
            digit++;
        }

        if (digit != 0u || started || divisors[i] == 1u) {
            uart_putc((char)('0' + digit));
            started = 1u;
        }
    }
}

static int uart_getc_nonblock(void)
{
    uint32_t value = UART_REG_DAT;
    return value == 0xffffffffu ? -1 : (int)(value & 0xffu);
}

static void lcd_wait_ready(void)
{
    while (LCD_REG_STS & 1u)
        ;
}

static void lcd_write_cmd(uint8_t value)
{
    lcd_wait_ready();
    LCD_REG_CMD = value;
}

static void lcd_write_data(uint8_t value)
{
    lcd_wait_ready();
    LCD_REG_DAT = value;
}

static void lcd_set_cursor(uint8_t row, uint8_t col)
{
    lcd_write_cmd((uint8_t)(0x80u | (row ? 0x40u : 0x00u) | (col & 0x0fu)));
}

static void lcd_puts(const char *s)
{
    while (*s)
        lcd_write_data((uint8_t)*s++);
}

static void lcd_clear_line(uint8_t row)
{
    uint32_t i;

    lcd_set_cursor(row, 0);
    for (i = 0; i < 16u; i++)
        lcd_write_data(' ');
    lcd_set_cursor(row, 0);
}

static void lcd_show_banner(void)
{
    lcd_write_cmd(0x01u);
    lcd_set_cursor(0, 0);
    lcd_puts("Laptop -> LCD");
    lcd_set_cursor(1, 0);
    lcd_puts("                ");
    lcd_set_cursor(1, 0);
}

static void lcd_begin_new_message(void)
{
    lcd_clear_line(1);
}

static void lcd_handle_rx_char(int ch, uint8_t *rx_col, uint8_t *new_message)
{
    if (*new_message) {
        lcd_begin_new_message();
        *rx_col = 0;
        *new_message = 0;
    }

    if (ch == '\r')
        return;

    if (ch == '\n') {
        *new_message = 1;
        return;
    }

    if (ch == 0x08 || ch == 0x7f) {
        if (*rx_col != 0) {
            (*rx_col)--;
            lcd_set_cursor(1, *rx_col);
            lcd_write_data(' ');
            lcd_set_cursor(1, *rx_col);
        }
        return;
    }

    if (ch < 32 || ch > 126)
        return;

    if (*rx_col >= 16u)
        return;

    lcd_set_cursor(1, *rx_col);
    lcd_write_data((uint8_t)ch);
    (*rx_col)++;
}

int main(void)
{
    uint32_t led_val = 0x01u;
    uint32_t status_id = 0u;
    uint32_t status_countdown = STATUS_PERIOD_LOOPS;
    uint32_t rx_idle_countdown = 0u;
    uint32_t loops = 0u;
    uint8_t rx_col = 0u;
    uint8_t lcd_new_message = 1u;
    volatile uint32_t delay;

    UART_REG_DIV = CLOCK_HZ / UART_BAUD;
    lcd_show_banner();
    uart_puts("DE2i-150 PicoRV32 UART ready.\n");

    while (1) {
        int ch;

        while ((ch = uart_getc_nonblock()) >= 0) {
            if (rx_idle_countdown == 0u)
                lcd_new_message = 1u;
            lcd_handle_rx_char(ch, &rx_col, &lcd_new_message);
            rx_idle_countdown = RX_IDLE_RESTART_LOOPS;
        }

        for (delay = 0; delay < 50000u; delay++) {
            __asm__ volatile ("nop");
        }

        if (rx_idle_countdown != 0u)
            rx_idle_countdown--;

        loops++;
        if (loops >= 20u) {
            loops = 0u;
            LED_REG = led_val;
            led_val <<= 1;
            if (led_val == 0u || led_val > 0x80u)
                led_val = 0x01u;
        }

        status_countdown--;
        if (status_countdown == 0u) {
            status_countdown = STATUS_PERIOD_LOOPS;
            status_id++;
            uart_put_u32(status_id);
            uart_puts(": DE2i-150 PicoRV32 is alive.\n");
        }
    }
}
