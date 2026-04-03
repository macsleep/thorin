
| Memory Map
RAM_STBRT = 0x00000       | beginning of ram
RAM_HEAP = 0x00400        | beginning of heap
RAM_SIZE = 0x08000        | 32KB SRAM

.include "mfp.inc"

| setup
.org RAM_HEAP
        move.b #0xff, MFP_DDR            | set gpio to output

| loop
loop:
        move.b #0x55, MFP_GPDR           | output leds
        move #25, %d0                    | 250 ms
        jsr delay                        | wait

        move.b #0xaa, MFP_GPDR           | output leds
        move #25, %d0                    | 250 ms
        jsr delay                        | wait

        bra.s        loop


| functions
delay:
        movem.l %d0-%d2, -(%sp)          | push registers
        move.l %d0, %d2                  | save delay
        move #8, %d0                     | centis command
        trap #15                         | get centis
        add.l %d1, %d2                   | add centis to delay
1:      move #8, %d0                     | centis command
        trap #15                         | get centis
        cmp.l %d1, %d2                   | delay reached
        bgt 1b                           | if not wait
        movem.l (%sp)+, %d0-%d2          | pop registers
        rts

