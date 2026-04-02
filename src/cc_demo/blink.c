
#include <stdint.h>
#include <stdbool.h>

#define MFP 0xf8000
#define MFP_GPDR (*(uint8_t *)(MFP+0x01))
#define MFP_DDR  (*(uint8_t *)(MFP+0x05))
#define MFP_IERA (*(uint8_t *)(MFP+0x07))
#define MFP_IMRA (*(uint8_t *)(MFP+0x13))
#define MFP_VR   (*(uint8_t *)(MFP+0x17))
#define MFP_TBCR (*(uint8_t *)(MFP+0x1b))
#define MFP_TBDR (*(uint8_t *)(MFP+0x21))


volatile uint32_t count = 0;

__attribute__((interrupt)) void isr_timer_b(void) {
        count++;
}

void delay_timer_b(int n) {
        uint32_t timeout = count + n;
        while(count < timeout) {
                asm("nop");
        }
}

uint32_t centis() {
        uint32_t ticks;

        __asm__ volatile (
                "move #8, %%d0\n\t"
                "trap #15\n\t"
                "move.l %%d1, %0\n\t"
                : "=r"(ticks)                        // output
                :                                 // input
                : "d0", "d1", "cc", "memory"        // clobbers
        );

        return ticks;
}

void delay_centis(int n) {
        uint32_t timeout = centis() + n;
        while(centis() < timeout) {
                asm("nop");
        }
}

int main(void) {
        bool up = false;

        // install interrupt service routine
        uint32_t *vector_table = (uint32_t *)0x00000000;
        vector_table[64+8] = (uint32_t)isr_timer_b;

        MFP_DDR = 0xff;                // gpio as output
        MFP_VR = 0x40;                // MFP interrupts start at 0x100
        MFP_TBCR |= 0x15;        // frequency 2457600 Hz / 64 / (192 *2)
        MFP_TBDR = 192;                // timer b value
        MFP_IERA |= 0x01;        // enable timer b interrupt
        MFP_IMRA |= 0x01;        // timer b interrupt mask

        MFP_GPDR = 0x01;
        while(true) {
                if (MFP_GPDR & 0x81) up = !up;
                MFP_GPDR = up ? MFP_GPDR << 1 : MFP_GPDR >> 1;
                delay_timer_b(10);        // wait 100ms
                // delay_centis(10);        // wait 100ms
        }
}

