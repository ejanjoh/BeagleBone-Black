/******************************************************************************
 *  clock.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-11-07
 *
 * Reference: 
 *      - chapter 2, 7, 8 and 25 (AM335x TRM)
 *
 ******************************************************************************/


/* Clock registers... */
/* Clock Base */
    .equ    CM_WKUP,    0x44E00400 /* Clock Module Wakeup Registers */
    .equ    CM_PER,     0x44E00000 /* Clock Module Peripheral Registers */

/* Clock Offset */
    .equ    CM_PER_EMIF_CLKCTRL,    0x28    /* 32 bit, base: CM_PER  */
    .equ    CM_PER_GPIO1_CLKCTRL,   0xAC    /* 32 bit, base: CM_PER  */
    .equ    CM_PER_L3_CLKCTRL,      0xE0    /* 32 bit, base: CM_PER  */

    .equ    CM_WKUP_GPIO0_CLKCTRL,  0x08    /* 32 bit, base: CM_WKUP */
    .equ    CM_IDLEST_DPLL_DDR,     0x34    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKSEL_DPLL_DDR,     0x40    /* 32 bit, base: CM_WKUP */
    .equ    CM_IDLEST_DPLL_CORE,    0x5C    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKSEL_DPLL_CORE,    0x68    /* 32 bit, base: CM_WKUP */
    .equ    CM_IDLEST_DPLL_PER,     0x70    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M4_DPLL_CORE,    0x80    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M5_DPLL_CORE,    0x84    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKMODE_DPLL_PER,    0x8C    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKMODE_DPLL_CORE,   0x90    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKMODE_DPLL_DDR,    0x94    /* 32 bit, base: CM_WKUP */
    .equ    CM_CLKSEL_DPLL_PER,     0x9C    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M2_DPLL_DDR,     0xA0    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M2_DPLL_PER,     0xAC    /* 32 bit, base: CM_WKUP */
    .equ    CM_WKUP_UART0_CLKCTRL,  0xB4    /* 32 bit, base: CM_WKUP */
    .equ    CM_DIV_M6_DPLL_CORE,    0xD8    /* 32 bit, base: CM_WKUP */




        /*********************************************************************** 
         * ClockEnableGPIO0
         *
         * Enable the interface and functional clocks on GPIO0
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
         * ClockEnableEMIF
         *
         * Enable the interface and functional clocks needed by EMIF
         *
         * C prototype: void ClockEnableEMIF(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ClockEnableEMIF
ClockEnableEMIF:
        ldr     r0, =CM_PER
        mov     r1, #0x2            /* enable module */
1:
        str     r1, [r0, #CM_PER_EMIF_CLKCTRL]
2:
        ldr     r2, [r0, #CM_PER_EMIF_CLKCTRL]
        cmp     r2, r1
        bne     2b
3:
        str     r1, [r0, #CM_PER_L3_CLKCTRL]
4:
        ldr     r2, [r0, #CM_PER_L3_CLKCTRL]
        cmp     r2, r1
        bne     4b

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

        base    .req r0             /* the base address */
        val     .req r1             /* the value to be stored */
        tmp     .req r2             /* temporary */

        /* Core PLL Configuration
            - Set CORE_CLKOUTM4 to 200 MHz
            - Set CORE_CLKOUTM5 to 250 MHz
            - Set CORE_CLKOUTM6 to 500 MHz
            ---> CORE_CLKOUTM4/2 eq to 100 MHz
            ---> CORE_CLKOUTM5/2 eq to 125 MHz
            ---> CORE_CLKOUTM5/5 eq to 50 MHz
            ---> CORE_CLKOUTM5/5/10 eq to 5 MHz */
1:
        ldr     base, =CM_WKUP
        ldr     val, [base, #CM_CLKMODE_DPLL_CORE]
        bic     val, val, #0x7
        orr     val, val, #0x4
        str     val, [base, #CM_CLKMODE_DPLL_CORE]
2:
        ldr     val, [base, #CM_IDLEST_DPLL_CORE]
        and     val, val, #0x100
        cmp     val, #0
        beq     2b
3:
        ldr     val, [base, #CM_CLKSEL_DPLL_CORE]
        ldr     tmp, =0x7FFFF
        bic     val, val, tmp
        orr     val, val, #(992 << 8)                   /* M - value */
        orr     val, val, #23                           /* N - value */
        str     val, [base, #CM_CLKSEL_DPLL_CORE]
4:
        ldr     val, [base, #CM_DIV_M4_DPLL_CORE]
        bic     val, val, #0x1F
        orr     val, val, #10                           /* M4 - value */
        str     val, [base, #CM_DIV_M4_DPLL_CORE]

        ldr     val, [base, #CM_DIV_M5_DPLL_CORE]
        bic     val, val, #0x1F
        orr     val, val, #8                            /* M5 - value */
        str     val, [base, #CM_DIV_M5_DPLL_CORE]

        ldr     val, [base, #CM_DIV_M6_DPLL_CORE]
        bic     val, val, #0x1F
        orr     val, val, #4                            /* M6 - value */
        str     val, [base, #CM_DIV_M6_DPLL_CORE]
5:
        ldr     val, [base, #CM_CLKMODE_DPLL_CORE]
        bic     val, val, #0x7
        orr     val, val, #0x7
        str     val, [base, #CM_CLKMODE_DPLL_CORE]
6:
        ldr     val, [base, #CM_IDLEST_DPLL_CORE]
        and     val, val, #0x1
        cmp     val, #0
        beq     6b

        /* Peripheral PLL Configuration
            - Set PER_CLKOUTM2 to 192 MHz
            ---> PER_CLKOUTM2/2 eq to 96 MHz
            ---> PER_CLKOUTM2/4 eq to 48 MHz */
1:
        ldr     val, [base, #CM_CLKMODE_DPLL_PER]
        bic     val, val, #0x7
        orr     val, val, #0x4
        str     val, [base, #CM_CLKMODE_DPLL_PER]
2:
        ldr     val, [base, #CM_IDLEST_DPLL_PER]
        and     val, val, #0x100
        cmp     val, #0
        beq     2b
3:
        ldr     val, [base, #CM_CLKSEL_DPLL_PER]
        ldr     tmp, =0xFFFFF
        bic     val, val, tmp
        orr     val, val, #(960 << 8)                   /* M - value */
        orr     val, val, #23                           /* N - value */
        str     val, [base, #CM_CLKSEL_DPLL_PER]
4:
        ldr     val, [base, #CM_DIV_M2_DPLL_PER]
        bic     val, val, #0x7F
        orr     val, val, #5                            /* M2 - value */
        str     val, [base, #CM_DIV_M2_DPLL_PER]
5:
        ldr     val, [base, #CM_CLKMODE_DPLL_PER]
        bic     val, val, #0x7
        orr     val, val, #0x7
        str     val, [base, #CM_CLKMODE_DPLL_PER]
6:
        ldr     val, [base, #CM_IDLEST_DPLL_PER]
        and     val, val, #0x1
        cmp     val, #0
        beq     6b

        /* DDR PLL Configuration
            - Set DDR_PLL_CLKOUT to 400 MHz
            ---> DDR_PLL_CLKOUT/2 eq to 200 MHz */
1:
        ldr     val, [base, #CM_CLKMODE_DPLL_DDR]
        bic     val, val, #0x7
        orr     val, val, #0x4
        str     val, [base, #CM_CLKMODE_DPLL_DDR]
2:
        ldr     val, [base, #CM_IDLEST_DPLL_DDR]
        and     val, val, #0x100
        cmp     val, #0
        beq     2b
3:
        ldr     val, [base, #CM_CLKSEL_DPLL_DDR]
        ldr     tmp, =0x7FFFF
        bic     val, val, tmp
        ldr     tmp, =(266 << 8)
        orr     val, val, tmp                           /* M - value */
        orr     val, val, #23                           /* N - value */
        str     val, [base, #CM_CLKSEL_DPLL_DDR]
4:
        ldr     val, [base, #CM_DIV_M2_DPLL_DDR]
        bic     val, val, #0x1F
        orr     val, val, #1                            /* M2 - value */
        str     val, [base, #CM_DIV_M2_DPLL_DDR]
5:
        ldr     val, [base, #CM_CLKMODE_DPLL_DDR]
        bic     val, val, #0x7
        orr     val, val, #0x7
        str     val, [base, #CM_CLKMODE_DPLL_DDR]
6:
        ldr     val, [base, #CM_IDLEST_DPLL_DDR]
        and     val, val, #0x1
        cmp     val, #0
        beq     6b

        .unreq  base
        .unreq  val
        .unreq  tmp

        mov     pc, lr




