#include <stdint.h>

#define LED_REG (*(volatile uint32_t *)0x03000000u)

static void delay(volatile uint32_t count)
{
    while (count--) {
        __asm__ volatile ("nop");
    }
}

int main(void)
{
    uint32_t led_val = 0x01u;

    while (1) {
        LED_REG = led_val;
        delay(2000000u);

        led_val <<= 1;
        if (led_val == 0 || led_val > 0x80u)
            led_val = 0x01u;
    }
}
