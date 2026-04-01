# Thorin 68008 SBC

## Description

This is a project for a Motorola Corporation 68008 SBC (Single Board Computer). The key feature of this SBC is it's put together using TTL (Transistor to Transistor Logic) ICs. Except for the 32K EPROM there are no pre programmable components used in this build. The SBC also features a 32K SRAM and a 68901 MFP (Multi-Function Peripheral) which provides a UART (Universal Asynchronous Receiver Transmitter), parallel port and four timers. For more details please have a look at the [documentation](docs).

## History

I first build this SBC in the early 90s simply to learn something about computer hardware. The SBC has no purpose other than that. At the time I was able to build and test the hardware. But due to the lack of my own EPROM programmer I was not able to do much regarding software. Thirty plus years later I decided to reproduce the [schematics](docs/Schematics.md) from the original [wire warp board](docs/Hardware.md), create a PCB and write some [software](docs/Software.md) all of which you can find in this repository. And lastly the name Thorin is a reference to Thorin Oakenshield king of dwarves in J. R. R. Tolkien's "The Hobbit". This SBC might be small but it is also very mighty :-) .
