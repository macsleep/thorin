|
| S-Record boot loader for Thorin single board computer
| 15.12.2025 JS
|
| The 68901 UART and timer A are used by the bootloader.
|

| memory map
RAM_START = 0x00000
RAM_SSP = 0x07FFC
RAM_SIZE = 0x08000
ROM_START = 0x08000
ROM_CODE = 0x08008
ROM_SIZE = 0x08000

.include "interrupt.inc"
.include "mfp.inc"

| symbols
EOT = 0x04
RX_MASK = 0x0f
GET_CHAR = 5
PUT_CHAR = 6
PENDING_CHAR = 7
CENTIS = 8
PUT_STR = 14

| programm code
.org    ROM_START
        dc.l RAM_SSP                      | supervisor stack pointer
        dc.l ROM_CODE                     | program counter

setup:
        and.i #0x22ff, %sr                | supervisor mode, interrupt mask

        | zero ram
        move.l #RAM_START, %a0
        move.l #RAM_START+RAM_SIZE, %a1
1:      move.b #0, (%a0)+
        cmp.l %a0, %a1
        bne 1b

        | memory ring buffer
        move.l #0, %a6
        link %a6, #(RX_MASK+1+6)*-1
        move.b #0, (rx_start, %a6)
        move.b #0, (rx_end, %a6)
        move.l #0, (centis, %a6)

        | memory s-records
        move.l #0, %a5
        link %a5, #(16)*-1
        move.l #0, (address, %a5)
        move.l #0, (start_address, %a5)
        move.w #0, (record_count, %a5)
        move.w #0, (checksum, %a5)
        move.b #0, (record_type, %a5)
        move.b #0, (address_length, %a5)
        move.b #0, (byte_count, %a5)

        | init hardware
        bsr init_mfp
        bsr init_interrupts

loop:
        | S character
1:      bsr read_char
        cmp.b #'S', %d0
        beq.s 2f

        | End Of Text
        cmp.b #EOT, %d0
        bne 1b
        move.b #'\n', %d0
        bsr write_char
        move.l (start_address, %a5), %a0
        cmp.l #0, %a0
        beq 1b                            | nothing to execute
        unlk %a5                          | free s-record memory
        jsr (%a0)                         | execute code
        | return from code
        bra restart

        | record type
2:      bsr read_char
        move.b #2, (address_length, %a5)
        cmp.b #'1', %d0
        beq.s 3f
        move.b #3, (address_length, %a5)
        cmp.b #'2', %d0
        beq.s 3f
        move.b #4, (address_length, %a5)
        cmp.b #'3', %d0
        beq.s 3f
        move.b #4, (address_length, %a5)
        cmp.b #'7', %d0
        beq.s 3f
        move.b #3, (address_length, %a5)
        cmp.b #'8', %d0
        beq.s 3f
        move.b #2, (address_length, %a5)
        cmp.b #'9', %d0
        beq.s 3f
        bra 1b
3:      bsr hex_to_nibble
        cmp.b #0xf, %d0
        bgt 1b
        move.b %d0, (record_type, %a5)

        | byte count
        bsr hex_to_byte
        cmp #0xff, %d0
        bgt 1b
        move #0, (checksum, %a5)
        add %d0, (checksum, %a5)
        move.b %d0, (byte_count, %a5)

        | address
        clr.l %d1                         | temp
        move.b (address_length, %a5), %d2
4:      bsr hex_to_byte
        cmp #0xff, %d0
        bgt 1b
        add %d0, (checksum, %a5)
        lsl.l #8, %d1
        add %d0, %d1                      | temp
        sub.b #1, %d2
        bne.s 4b
        move.l %d1, (address, %a5)

        | start address
        cmp.b #7, (record_type, %a5)
        beq.s 5f
        cmp.b #8, (record_type, %a5)
        beq.s 5f
        cmp.b #9, (record_type, %a5)
        beq.s 5f
        bra.s 6f
5:      move.l %d1, (start_address, %a5)
        
        | data
6:      clr.l %d1
        move.b (byte_count, %a5), %d1
        sub.b (address_length, %a5), %d1
        sub.b #1, %d1                     | checksum
        blt 1b
        beq.s 8f
        move.l (address, %a5), %a0
7:      bsr hex_to_byte
        cmp #0xff, %d0
        bgt 1b
        add %d0, (checksum, %a5)
        move.b %d0, (%a0)+                | save data to memory
        subi #1, %d1
        bne 7b

        | checksum
8:      not (checksum, %a5)
        and #0x00ff, (checksum, %a5)
        bsr hex_to_byte
        cmp #0xff, %d0
        bgt 1b
        clr.l %d1
        move (checksum, %a5), %d1
        cmp %d0, %d1
        beq.s 9f
        lea.l checksum_error, %a0
        bsr print_string
        bra 1b

        | progress
9:      add #1, (record_count, %a5)
        move.b #'.', %d0
        bsr write_char

        bra loop

restart:
        bclr.b #0, MFP_TSR                | stop transmitter
1:      btst.b #4, MFP_TSR                | check if ready
        beq.s 1b                          | wait if not
        reset                             | reset peripherals
        move.l #RAM_SSP, %ssp             | stack pointer
        bra setup                         | start bootloader

| sub routines
init_mfp:
        | gpio
        move.b #0xff, MFP_DDR             | gpio to output
        move.b #0x00, MFP_GPDR            | leds off
        | timer a
        or.b #0x15, MFP_TACR              | frequency 2457600 Hz / 64 / 384
        move.b #192, MFP_TADR             | timer a value
        | uart
        move.b #0x02, MFP_TCDR            | 1/4 transmitter clock
        move.b #0x02, MFP_TDDR            | 1/4 receiver clock
        move.b #0x11, MFP_TCDCR           | divide by 4
        move.b #0x98, MFP_UCR             | 9600 8N1
        move.b #0x01, MFP_RSR             | start receiver 
        move.b #0x05, MFP_TSR             | start transmitter
        move.b #0x40, MFP_VR              | MFP interrupts start at 0x100
        or.b #0x38, MFP_IERA              | enable rx/timer interrupts
        or.b #0x38, MFP_IMRA              | rx/timer interrupt mask
        rts

| centis delay in d0
delay:
        movem.l %d0/%a0, -(%sp)
        lea.l (centis, %a6), %a0
        add.l (%a0), %d0
1:      cmp.l (%a0), %d0
        bgt 1b
        movem.l (%sp)+, %d0/%a0
        rts

| write char in d0
write_char:
1:      btst.b #7, MFP_TSR                | check if ready
        beq.s 1b                          | wait if not
        move.b %d0, MFP_UDR               | transmit
        rts

| return char in d0
read_char:
        movem.l %d1-%d2/%a0, -(%sp)
1:      clr.l %d1
        move.b (rx_start, %a6), %d1
        clr.l %d2
        move.b (rx_end, %a6), %d2
        cmp %d1, %d2
        beq.s 1b
        lea.l (rx_buffer, %a6), %a0
        clr.l %d0
        move.b (%d1, %a0), %d0            | get value
        add #1, %d1
        and #RX_MASK, %d1
        move.b %d1, (rx_start, %a6)
        movem.l (%sp)+, %d1-%d2/%a0
        rts

| return 0 or 1 in d0
pending_char:
        movem.l %a0-%a1, -(%sp)
        clr.l %d0
        lea.l (rx_start, %a6), %a0
        lea.l (rx_end, %a6), %a1
        cmpm.b (%a0)+, (%a1)+             | one instruction cmp
        beq.s 1f
        move.b #1, %d0
1:      movem.l (%sp)+, %a0-%a1
        rts

| string start in a0
print_string:
        movem.l %d0-%d1/%a0, -(%sp)
        move #0xff, %d1
1:      move.b (%a0)+, %d0
        tst %d0
        beq.s 2f
        bsr write_char
        dble %d1, 1b
2:      movem.l (%sp)+, %d0-%d1/%a0
        rts

hex_to_byte:
        movem.l %d1, -(%sp)
        clr.l %d1
        bsr read_char
        bsr hex_to_nibble
        cmp.b #0x0f, %d0
        bgt.s 1f
        lsl #4, %d0
        add.b %d0, %d1
        bsr read_char
        bsr hex_to_nibble
        cmp.b #0x0f, %d0
        bgt.s 1f
        add.b %d1, %d0
        bra.s 2f
1:      move #0x100, %d0                 | not hex
2:      movem.l (%sp)+, %d1
        rts

hex_to_nibble:
        cmp #'0', %d0
        blt.s 1f
        cmp #'9', %d0
        bgt.s 1f
        sub #'0', %d0
        bra.s 3f
1:      cmp #'A', %d0
        blt.s 2f
        cmp #'F', %d0
        bgt.s 2f
        sub #'A', %d0
        add #10, %d0
        bra.s 3f
2:      move #0x10, %d0                  | not hex
3:      rts

| interrupt
init_interrupts:
        movem.l %a0, -(%sp)

        | group 0
        lea.l RAM_SSP, %a0
        move.l %a0, INTR_RESET_SP
        lea.l ROM_CODE, %a0
        move.l %a0, INTR_RESET_PC
        lea.l isr_bus_error, %a0
        move.l %a0, INTR_BUS_ERROR
        lea.l isr_address_error, %a0
        move.l %a0, INTR_ADDRESS_ERROR

        | group 1
        lea.l isr_illegal_instruction, %a0
        move.l %a0, INTR_ILLEGAL_INSTRUCTION

        | group 2
        lea.l isr_division_by_zero, %a0
        move.l %a0, INTR_DIVISION_BY_ZERO
        lea.l isr_trap15, %a0
        move.l %a0, INTR_TRAP15

        | mfp
        lea.l isr_timer_a, %a0
        move.l %a0, INTR_TIMER_A
        lea.l isr_receive_error, %a0
        move.l %a0, INTR_RECEIVE_ERROR
        lea.l isr_receiver_buffer_full, %a0
        move.l %a0, INTR_RECEIVER_BUFFER_FULL

        movem.l (%sp)+, %a0
        rts

| interrupt service routines
isr_bus_error:
        lea intr_bus_error, %a0
        bsr print_string
        stop #0x2700

isr_address_error:
        lea intr_address_error, %a0
        bsr print_string
        stop #0x2700

isr_illegal_instruction:
        lea intr_illegal_instruction, %a0
        bsr print_string
        stop #0x2700

isr_division_by_zero:
        lea intr_division_by_zero, %a0
        bsr print_string
        stop #0x2700

isr_trap15:
        movem.l %d0, -(%sp)
        cmp #GET_CHAR, %d0                 | read char
        bne 1f
        bsr read_char
        move.l %d0, %d1
        bra 6f
1:      cmp #PUT_CHAR, %d0                 | write char
        bne 2f
        move.b %d1, %d0
        bsr write_char
        bra 6f
2:      cmp #PENDING_CHAR, %d0             | check for char
        bne 3f
        bsr pending_char
        move.l %d0, %d1
        bra 6f
3:      cmp #CENTIS, %d0                   | get centisecond timer
        bne 4f
        lea.l (centis, %a6), %a0
        move.l (%a0), %d1
        bra 6f
4:      cmp #PUT_STR, %d0                  | print string
        bne 6f
        bsr print_string
        bra 6f
6:      movem.l (%sp)+, %d0
        rte

isr_timer_a:
        add.l #1, (centis, %a6)
        rte

isr_receive_error:
        | break
        btst.b #3, MFP_RSR
        beq.s 1f
        bra restart
        | other
1:      lea intr_receive_error, %a0
        bsr print_string
        rte

isr_receiver_buffer_full:
        movem.l %d0-%d2/%a0, -(%sp)
        clr.l %d0
        move.b MFP_UDR, %d0                | get uart
        clr.l %d2
        move.b (rx_end, %a6), %d2
        lea.l (rx_buffer, %a6), %a0
        move.b %d0, (%d2, %a0)             | save value
        add #1, %d2
        and #RX_MASK, %d2
        move.b %d2, (rx_end, %a6)
        clr.l %d1
        move.b (rx_start, %a6), %d1
        cmp %d1, %d2
        bne.s 1f
        add #1, %d1                        | overflow
        and #RX_MASK, %d1
        move.b %d1, (rx_start, %a6)
1:      movem.l (%sp)+, %d0-%d2/%a0
        rte

| constants
checksum_error:
        .ascii "S-Record Checksum Error"
        dc.b '\r','\n',0
intr_bus_error:
        .ascii "Bus Error"
        dc.b '\r','\n',0
intr_address_error:
        .ascii "Address Error"
        dc.b '\r','\n',0
intr_illegal_instruction:
        .ascii "Illegal Instruction"
        dc.b '\r','\n',0
intr_division_by_zero:
        .ascii "Division by Zero"
        dc.b '\r','\n',0
intr_receive_error:
        .ascii "UART Receive Error"
        dc.b '\r','\n',0

| memory structs
        .struct 3 - RX_MASK
rx_buffer:
        .struct rx_buffer - 1
rx_start:
        .struct rx_buffer - 2
rx_end:
        .struct rx_buffer - 6
centis:

        .struct 0
address:
        .struct address - 4
start_address:
        .struct address - 6
checksum:
        .struct address - 8
record_count:
        .struct address - 9
record_type:
        .struct address - 10
address_length:
        .struct address - 11
byte_count:

