
TARGET = bootloader
AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy
ASFLAGS = -m68008 -alms=$(TARGET).lst -I include

SRC = $(TARGET).s
OBJ = $(TARGET).o

all: $(TARGET).srec

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET).srec: $(OBJ)
	$(OBJCOPY) -O srec $< $@
	srec_cat $@ -crop 0x08000 0x10000 -offset -0x08000 -o $@

clean:
	$(RM) $(OBJ) $(TARGET).lst $(TARGET).srec

eprom: $(TARGET).srec
	# minipro -p M27C256B@DIP28 -b
	minipro -p M27C256B@DIP28 -f srec -w $< -y

