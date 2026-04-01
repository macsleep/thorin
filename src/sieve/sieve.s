|
| Sieve of Eratosthenes using bits
| 28.2.2025 JS
|

| memory map
RAM_START = 0x00000
RAM_HEAP = 0x400
RAM_SIZE = 0x08000

| defines
SIZE = 1024*8*30	| should be multiple of 8

| programm code
.org	RAM_HEAP

setup:
	| malloc
	link %a5, #SIZE/8*-1
	move.l %sp, %a4
	add.l #4, %a4		| memory base

	| init sieve
	move.l #0, %d1
	move.l %a4, %a1
1:	move.b #0xff, (%a1)+
	add.l #1, %d1
	cmp.l #SIZE/8, %d1
	bne 1b

	| foreach prime
	move.l #2, %d1		| first prime
2:	move.l %a4, %a1
	move.l %d1, %d3		| byte offset
	lsr.l #3, %d3
	move.l %d1, %d4		| bit offset
	and.l #0x7, %d4
	add.l %d3, %a1
	btst.b %d4, (%a1)	| if set = prime
	beq 4f

	| print prime
	move.l %d1, %d0
	bsr print_word_dec
	move.l #' ', %d0
	bsr write_char

	| remove multiples
	move.l %d1, %d2		| load prime
3:	add.l %d1, %d2		| add mulitiple
	cmp.l #SIZE, %d2	| exit loop
	bge 4f		
	move.l %d2, %d3		| byte offset
	lsr.l #3, %d3
	move.l %d2, %d4		| bit offset
	and.l #0x7, %d4
	move.l %a4, %a1
	add.l %d3, %a1
	bclr.b %d4, (%a1)	| clear multiple
	bra 3b
	
	| foreach end
4:	add.l #1, %d1
	cmp.l #SIZE, %d1
	bne 2b

	unlk %a5		| free memory
	rts			| return to bootloader

| sub routines
write_char:
	movem.l %d1, -(%sp)
	move.b %d0, %d1
	move #6, %d0
	trap #15
	move.b %d1, %d0
	movem.l (%sp)+, %d1
	rts

print_string:
	movem.l %d0/%a0, -(%sp)
1:	move.b (%a0)+, %d0	| address of character
	cmp.b #0, %d0		| end of string
	beq.s 2f
	bsr write_char
	bra.s 1b
2:	movem.l (%sp)+, %d0/%a0
	rts

print_word_dec:
	movem.l %d0-%d2, -(%sp)
	move.l #0, %d2
1:	move.l #10, %d1
	bsr divu32
	add.b #'0', %d1
	move.w %d1, -(%sp)
	add.l #1, %d2
	tst.l %d0
	bne.s 1b
2:	move.w (%sp)+, %d0
	bsr write_char
	sub.l #1, %d2
	bne.s 2b
	movem.l (%sp)+, %d0-%d2
	rts

| dividend in d0
| divider (16 bit) in d1
| return quotient in d0
| return modulo in d1
divu32:
	movem.l %d2-%d4, -(%sp)
	move.l %d0, %d3		| move dividend
	clr.w %d3		| clear lower word
	swap %d3		| move 31:16 to 15:0
	divu %d1, %d3		| div upper word divisor
	move.w %d3, %d4		| save 1. quotient
	move.w %d0, %d3		| merge 1. remainder and lower word divisor
	divu %d1, %d3		| div remainder and lower word divisor
	swap %d4		| move 1. quotient to upper word
	move.w %d3, %d4		| save 2. quotient to lower word
	move.l %d4, %d0		| save quotient in d0
	clr.w %d3		| clear 2. quotient
	swap %d3		| get 2. remainder into lower word
	move.w %d3, %d1		| save remainder in d1
	movem.l (%sp)+, %d2-%d4
	rts

| constants
newline:
	dc.b '\r','\n',0

