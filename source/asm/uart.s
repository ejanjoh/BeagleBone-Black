/******************************************************************************
 *  uart.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-11-08
 *
 *  Reference: 
 *      - chapter 2, 8 and 19 (AM335x TRM)
 *
 ******************************************************************************/

/* UART registers */
/* UART Base */
    .equ    UART0,          0x44E09000      /* UART0 register */

/* UART Offset */
    .equ    UART_THR,       0x0             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_DLL,       0x0             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_DLH,       0x4             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_IER_UART,  0x4             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_EFR,       0x8             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_FCR,       0x8             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_LCR,       0xC             /* 16 bit, base GPIO0 to 5 */
    .equ    UART_MCR,       0x10            /* 16 bit, base GPIO0 to 5 */
    .equ    UART_LSR_UART,  0x14            /* 16 bit, base GPIO0 to 5 */
    .equ    UART_MDR1,      0x20            /* 16 bit, base GPIO0 to 5 */
    .equ    UART_SYSC,      0x54            /* 16 bit, base GPIO0 to 5 */
    .equ    UART_SYSS,      0x58            /* 16 bit, base GPIO0 to 5 */




        /*********************************************************************** 
         * UART_PutChar
         *
         * Transmit or put a char on UART0/serial interface (according to the 
         * BBB System Reference Manual the serial pins/serial debug port are 
         * connected to the UART0)
         *
         * in: r0 - char to be placed on UART0
         *
         * C prototype: void UART_PutChar(const char c) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global UART_PutChar
UART_PutChar:

        and     r0, r0, #0xFF

        /* UART0 base address */
        ldr     r1, =UART0

        /* Secure that UART is ready to tramsmit a char */
1:
        ldrh    r2, [r1, #UART_LSR_UART]
        and     r2, r2, #0x20               /* ready to transmit? */
        cmp     r2, #0
        beq     1b
2:
        strh    r0, [r1, #UART_THR]
        mov     pc, lr


        /*********************************************************************** 
         * 
         *
         * Transmit or put a null terminated string on UART0/serial interface.
         * If there is a null termination before the len:th char it will stop 
         * putting chars on the serial interface. If not, it will stop at len:th
         * char.
         *
         * in: r0 - a pointer to a null terminated string
         *     r1 - the maximum lenght of the string
         *
         * C prototype: void UART_PutString(char *str, uint32_t len) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global UART_PutString
UART_PutString:
        stmfd   sp!, {r4, lr}
        mov     r2, r0
        ldrb    r0, [r2]
1:
        and     r0, r0, #0xFF
        cmp     r0, #0x0
        beq     10f
        cmp     r1, #0x0
        beq     10f

        stmfd   sp!, {r0-r3}
        bl      UART_PutChar
        ldmfd   sp!, {r0-r3}

        sub     r1, r1, #1
        ldrb    r0, [r2, #1]!
        b       1b

10:
        ldmfd   sp!, {r4, pc}

        /*********************************************************************** 
         *  UART_SetupSerialUART0
         *
         *  Setup a serial interface on UART0 as:
         *      - 115200 baud
         *      - 8 data bits
         *      - 1 stop bit
         *      - no parity
         *      - no interrupt
         *
         * C prototype: void UART_SetupSerialUART0(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global UART_SetupSerialUART0
UART_SetupSerialUART0:
        stmfd   sp!, {r7-r9}

        /* *** Software reset - UART *** */
        ldr     r0, =UART0
        add     r1, r0, #UART_SYSC      /* ldrh can only handle 5 bit offset */
1:
        ldrh    r2, [r1]
        orr     r2, r2, #0x2
        strh    r2, [r1]

        add     r1, r0, #UART_SYSS
        /* loop until reset is performed */
2:
        ldrh    r2, [r1]
        and     r2, r2, #0x1
        cmp     r2, #0
        beq     2b

        /* *** FIFOs and DMA Settings *** */
        ldr     r0, =UART0
1:
        ldrh    r7, [r0, #UART_LCR]             /* r7 = UART_LCR */
        mov     r2, #0xBF
        strh    r2, [r0, #UART_LCR]
2:
        ldrh    r8, [r0, #UART_EFR]             /* r8 = UART_EFR */
        orr     r2, r8, #(1 << 4)
        strh    r2, [r0, #UART_EFR]
3:
        mov     r2, #0x80
        strh    r2, [r0, #UART_LCR]
4:
        add     r1, r0, #UART_MCR
        ldrh    r9, [r1]                        /* r9 = UART_MCR */
        orr     r2, r9, #(1 << 6)
        strh    r2, [r1]
5:
        mov     r2, #0x0                        /* No DMA nor FIFO */
        strh    r2, [r0, #UART_FCR]
6:
        mov     r2, #0xBF
        strh    r2, [r0, #UART_LCR]
7:
        /* Skipped, no FIFO in use */
8:
        /* Skipped, No FIFO nor DMA in use */
9:
        and     r8, r8, #(1 << 4)
        ldrh    r2, [r0, #UART_EFR]
        bic     r2, r2, #(1 << 4)
        orr     r2, r2, r8
        strh    r2, [r0, #UART_EFR]
10:
        mov     r2, #0x80
        strh    r2, [r0, #UART_LCR]
11:
        and     r9, r9, #(1 << 6)
        ldrh    r2, [r0, #UART_MCR]
        bic     r2, r2, #(1 << 6)
        orr     r2, r2, r9
        str     r2, [r0, #UART_MCR]
12:
        strh    r7, [r0, #UART_LCR]

        /* *** UART serial settings *** */
        ldr     r0, =UART0
        add     r1, r0, #UART_MDR1      /* ldrh can only andle 5 bit offset */

1:
        ldrh    r2, [r1]
        orr     r2, r2, #0x7
        strh    r2, [r1]
2:
        mov     r2, #0xBF
        strh    r2, [r0, #UART_LCR]
3:
        ldrh    r7, [r0, #UART_EFR]             /* r7 = UART_EFR... */
        mov     r2, r7
        orr     r2, r2, #(1 << 4)
        strh    r2, [r0, #UART_EFR]
4:
        mov     r2, #0x0
        strh    r2, [r0, #UART_LCR]
5:
        mov     r2, #0x0
        strh    r2, [r0, #UART_IER_UART]
6:
        mov     r2, #0xBF
        strh    r2, [r0, #UART_LCR]
7:
        mov     r2, #0x1A                       /* DLL-part of 115200 baud */
        strh    r2, [r0, #UART_DLL]
        mov     r2, #0x0                        /* DLH-part of 115200 baud */
        strh    r2, [r0, #UART_DLH]
8:
        mov     r2, #0x0
        strh    r2, [r0, #UART_LCR]
9:
        mov     r2, #0x0                        /* Interrupt isn't enabled */
        strh    r2, [r0, #UART_IER_UART]
10:
        mov     r2, #0xBF
        strh    r2, [r0, #UART_LCR]
11:
        ldrh    r2, [r0, #UART_EFR]
        bic     r2, #(1 << 4)
        and     r7, r7, #(1 << 4)
        orr     r2, r2, r7
        strh    r2, [r0, #UART_EFR]             /* Restore UART_EFR */
12:
        mov     r2, #0x3                        /* 8 bit chars */
        add     r2, r2, #(1 << 2)               /* 1 stop bit */
                                                /* no parity */
        strh    r2, [r0, #UART_LCR]
13:
        ldrh    r2, [r1]                /* ldrh can only andle 5 bit offset */
        bic     r2, #7                          /* UART 16x mode */
        strh    r2, [r1]

        ldmfd   sp!, {r7-r9}
        mov     pc, lr




