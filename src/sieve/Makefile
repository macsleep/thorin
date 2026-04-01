
TARGET = sieve

AS = m68k-linux-gnu-as
OBJCOPY = m68k-linux-gnu-objcopy
ASFLAGS = -m68008 -alms=$(TARGET).lst -I include

SRC = $(TARGET).s
OBJ = $(TARGET).o

all: $(TARGET).srec

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET).srec: $(OBJ)
	$(OBJCOPY) -O srec $< $@
	srec_cat $@ -crop 0x00400 0x07fff -execution-start-address=0x400 -o $@

clean:
	$(RM) $(OBJ) $(TARGET).lst $(TARGET).srec

down:
	down.pl -m -d /dev/ttyUSB0 -f $(TARGET).srec

