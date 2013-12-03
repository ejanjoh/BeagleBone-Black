/******************************************************************************
 *  clock.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-11-07
 *
 * Reference: 
 *      - chapter 2, 8 and 25 (AM335x TRM)
 *
 ******************************************************************************/


/* Clock registers... */
/* Clock Base */
    .equ    CM_WKUP,    0x44E00400 /* Clock Module Wakeup Registers */
    .equ    CM_PER,     0x44E00000 /* Clock Module Peripheral Registers */

/* Clock Offset */
    .equ    CM_WKUP_GPIO0_CLKCTRL,  0x8     /* 32 bit, base CM_WKUP  */
    .equ    CM_WKUP_UART0_CLKCTRL,  0xB4    /* 32 bit, base: CM_WKUP */
    .equ    CM_PER_GPIO1_CLKCTRL,   0xAC    /* 32 bit, base: CM_PER  */

    .equ    CM_IDLEST_DPLL_CORE,    0x5C    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKSEL_DPLL_CORE,    0x68    /* 32 bit, base: CM_WKUP */
    .equ    CM_IDLEST_DPLL_PER,     0x70    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M4_DPLL_CORE,    0x80    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKMODE_DPLL_PER,    0x8C    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKMODE_DPLL_CORE,   0x90    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKSEL_DPLL_PER,     0x9C    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M2_DPLL_PER,     0xAC    /* 32 bit, base: CM_WKUP */




        /*********************************************************************** 
         * ClockEnableGPIO0
         *
         * Enable the interface and functional clocks on GPIO1
         *
         * C prototype: void ClockEnableGPIO0(void) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ClockEnableGPIO0
ClockEnableGPIO0:
        ldr     r0, =CM_WKUP
        ldr     r1, =0x40002        /* functional and interface clocks */
        str     r1, [r0, #CM_WKUP_GPIO0_CLKCTRL]
1:
        ldr     r2, [r0, #CM_WKUP_GPIO0_CLKCTRL]
        cmp     r2, r1
        bne     1b
        mov     pc, lr


        /*********************************************************************** 
         * ClockEnableGPIO1
         *
         * Enable the interface and functional clocks on GPIO1
         *
         * C prototype: void ClockEnableGPIO1(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ClockEnableGPIO1
ClockEnableGPIO1:
        ldr     r0, =CM_PER
        ldr     r1, =0x40002            /* functional and interface clocks */
        str     r1, [r0, #CM_PER_GPIO1_CLKCTRL]
1:
        ldr     r2, [r0, #CM_PER_GPIO1_CLKCTRL]
        cmp     r2, r1
        bne     1b
        mov     pc, lr


        /*********************************************************************** 
         * ClockEnableUART0
         *
         * Enable the interface and functional clocks on UART0
         *
         * C prototype: void ClockEnableUART0(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ClockEnableUART0
ClockEnableUART0:
        ldr     r0, =CM_WKUP
        mov     r1, #0x2
        str     r1, [r0, #CM_WKUP_UART0_CLKCTRL]
1:
        ldr     r2, [r0, #CM_WKUP_UART0_CLKCTRL]
        cmp     r2, r1
        bne     1b
        mov     pc, lr


        /*********************************************************************** 
         * ClockInitPll
         *
         * Setup and init clock needed in the system
         *
         * C prototype: void ClockInitPll(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ClockInitPll
ClockInitPll:
        /* Core PLL Configuration
            - Set CORE_CLKOUTM4 to 200 MHz
            - Set CORE_CLKOUTM4/2 to 100 MHz */
1:
        ldr     r4, =CM_WKUP
        ldr     r5, [r4, #CM_CLKMODE_DPLL_CORE]
        bic     r5, r5, #0x7
        orr     r5, r5, #0x4
        str     r5, [r4, #CM_CLKMODE_DPLL_CORE]
2:
        ldr     r5, [r4, #CM_IDLEST_DPLL_CORE]
        and     r5, r5, #0x100
        cmp     r5, #0
        beq     2b
3:
        ldr     r5, [r4, #CM_CLKSEL_DPLL_CORE]
        ldr     r6, =0x7FFFF
        bic     r5, r5, r6
        orr     r5, r5, #(992 << 8)                 /* M - value */
        orr     r5, r5, #23                         /* N - value */
        str     r5, [r4, #CM_CLKSEL_DPLL_CORE]
4:
        ldr     r5, [r4, #CM_DIV_M4_DPLL_CORE]
        bic     r5, r5, #0x1F
        orr     r5, r5, #10                         /* M4 - value */
        str     r5, [r4, #CM_DIV_M4_DPLL_CORE]
5:
        ldr     r5, [r4, #CM_CLKMODE_DPLL_CORE]
        bic     r5, r5, #0x7
        orr     r5, r5, #0x7
        str     r5, [r4, #CM_CLKMODE_DPLL_CORE]
6:
        ldr     r5, [r4, #CM_IDLEST_DPLL_CORE]
        and     r5, r5, #0x1
        cmp     r5, #0
        beq     6b

        /* Configuring the Peripheral PLL
            - Set PER_CLKOUTM2 to 192 MHz
            - Set PER_CLKOUTM2/4 to 48 MHz */
1:
        ldr     r5, [r4, #CM_CLKMODE_DPLL_PER]
        bic     r5, r5, #0x7
        orr     r5, r5, #0x4
        str     r5, [r4, #CM_CLKMODE_DPLL_PER]
2:
        ldr     r5, [r4, #CM_IDLEST_DPLL_PER]
        and     r5, r5, #0x100
        cmp     r5, #0
        beq     2b
3:
        ldr     r5, [r4, #CM_CLKSEL_DPLL_PER]
        ldr     r6, =0xFFFFF
        bic     r5, r5, r6
        orr     r5, r5, #(960 << 8)                     /* M - value */
        orr     r5, r5, #23                             /* N - value */
        str     r5, [r4, #CM_CLKSEL_DPLL_PER]
4:
        ldr     r5, [r4, #CM_DIV_M2_DPLL_PER]
        bic     r5, r5, #0x7F
        orr     r5, r5, #5                              /* M2 - value */
        str     r5, [r4, #CM_DIV_M2_DPLL_PER]
5:
        ldr     r5, [r4, #CM_CLKMODE_DPLL_PER]
        bic     r5, r5, #0x7
        orr     r5, r5, #0x7
        str     r5, [r4, #CM_CLKMODE_DPLL_PER]
6:
        ldr     r5, [r4, #CM_IDLEST_DPLL_PER]
        and     r5, r5, #0x1
        cmp     r5, #0
        beq     6b

        mov     pc, lr




