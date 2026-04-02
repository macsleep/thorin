# Traps

The bootloader provides a few traps (software interrupts) for programs that want to access these functions in a portable way. 

## Read a Character from the UART
<pre>
GET_CHAR = 5

	move #GET_CHAR, %d0
	trap #15
	| character in %d1.b
</pre>

## Write a Character to the UART
<pre>
PUT_CHAR = 6

	move #PUT_CHAR, %d0
	move.b #'a', %d1
	trap #15
</pre>

## Check Read FIFO for Pending Character(s)
<pre>
PENDING_CHAR = 7

	move #PENDING_CHAR, %d0
	trap #15
	| 0 (nothing) or 1 (data available) in %d1.l
</pre>

## Get the Centi Seconds since Startup
<pre>
CENTIS = 8

	move #CENTIS, %d0
	trap #15
	| %d1.l contains the centi seconds
</pre>

## Write a Null Terminated String to the UART
<pre>
PUT_STR = 14

	lea.l text, %a0
	move #PUT_STR, %d0
	trap #15

text:
	.ascii "the quick brown fox jumps over the lazy dog"
	dc.b '\r','\n',0
</pre>
