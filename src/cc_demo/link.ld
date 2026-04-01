
ENTRY(_start)        /* Entry point symbol from your startup code */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000400, LENGTH = 32K 
}

SECTIONS
{
    /* Code and read-only data */
    .text :
    {
        _stext = .;          /* Start of text section */
        KEEP(*(.vectors))    /* Interrupt vectors if you have them */
        *(.text*)            /* All .text sections from object files */
        *(.rodata*)          /* Read-only data */
        _etext = .;          /* End of text section */
    } > RAM

    /* Initialized data */
    .data :
    {
        _sdata = .;          /* Start of data section */
        *(.data*)            /* All initialized data */
        _edata = .;          /* End of data section */
    } > RAM

    /* Uninitialized data (zero-initialized at startup) */
    .bss (NOLOAD) :
    {
        _sbss = .;           /* Start of BSS */
        *(.bss*)
        *(COMMON)            /* Common symbols */
        _ebss = .;           /* End of BSS */
    } > RAM

    /* Stack at the top of RAM */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}

