
TARGET = blink

CC = m68k-linux-gnu-gcc
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy

CFLAGS = -Wall -O2 -m68000 --param=min-pagesize=0
LDFLAGS = --defsym=_start=main -T link.ld --no-warn-rwx-segments

OBJ = $(TARGET).o

all: $(TARGET).srec

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(TARGET).elf: $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $<

$(TARGET).srec: $(TARGET).elf
	$(OBJCOPY) -O srec $< $@

clean:
	$(RM) $(OBJ) $(TARGET).elf $(TARGET).srec

down:
	down.pl -d /dev/ttyUSB0 -f $(TARGET).srec

