
all: Basic68.srec

Basic68.srec: Basic68.inc Basic68.x68
	vasmm68k_mot -quiet -m68000 -Fsrec -s28 -L Basic68.lst -o Basic68.srec Basic68.x68
	srec_cat Basic68.srec -execution-start-address=0x600 -address-length=3 -o Basic68.srec

clean:
	$(RM) Basic68.run Basic68.lst Basic68.srec

down:
	down.pl -m -d /dev/ttyUSB0 -f Basic68.srec


