/******************************************************************************
 *  start.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-11-07
 *
 *  Just a test...
 ******************************************************************************/

        /* ARM processor system modes */
        .equ    usr32_mode, 0b10000         /* user mode */
        .equ    sys32_mode, 0b11111         /* system mode */
        .equ    svc32_mode, 0b10011         /* supervisor mode */

        /* Clock registers, see chapter 2 and 8 (AM335x TRM)*/
        /* Base */
        .equ    CM_WKUP, 0x44E00400     /* Clock Module Wakeup Registers */
        .equ    CM_PER,  0x44E00000     /* Clock Module Peripheral Registers */

        /* Offset */
        .equ    CM_WKUP_CLKSTCTRL,      0x00     /* 32 bit, base: CM_WKUP */
        .equ    CM_PER_L3_CLKSTCTRL,    0x0C     /* 32 bit, base: CM_PER */


        /*********************************************************************** 
         * _start
         *
         * Global start of the software system
         *
         * C prototype: N/A 
         **********************************************************************/
        .section .init
        .code 32
        .align 2
        .global _start
_start:
        /* Change from current mode, supervisor, to system mode */
        mov     r0, #sys32_mode
        mrs     r1, cpsr
        bic     r1, r1, #0x1F
        orr     r1, r1, r0
        msr     cpsr_c, r1

        /* Set up the stack */
        ldr     sp, =__stack_top

        /* Zero out the bss, tbd... */

        /* Set up the interrupt vector table, tbd... */

        /* Set up the mux mapping */
        bl      CtrlModMuxUART0

        /* *** Could be removed, all relavant clocks are initiated by the 
               ROM_code. However, we set up the clocks needed... *** */

        /* Initiate clock source for UART0, EMIF etc... */
        bl      ClockInitPll

        /* Enforce that Clock Manager's used is a up an running... */
        mov     r6, #0x2            /* force wake-up */
        
        ldr     r4, =CM_WKUP
        str     r6,     [r4, #CM_WKUP_CLKSTCTRL]

        ldr     r4, =CM_PER
        str     r6, [r4, #CM_PER_L3_CLKSTCTRL]

        /* *** end init clocks *** */

        /* All relavant clocks are initiated by the ROM-code or above; but the 
           clocks needs to be enabled... */
        bl      GPIO_EnableUsrLeds          /* incl GPIO_EnableGPIO0 */
        bl      ClockEnableUART0
        bl      ClockEnableEMIF

        /* Turn on usr led 0 to indicate this point */
        mov     r0, #0x1
        bl      GPIO_TurnOnUsrLed

        /* Set baud rate, data bits etc */
        bl      UART_SetupSerialUART0

        /* Put something on UART0 */
        ldr     r0, =helloWorld$
        mov     r1, #0x20
        bl      UART_PutString

        /* *** test 1 *** */
        ldr     r0, =(CM_PER + CM_PER_L3_CLKSTCTRL)
        mov     r1, #0x1
        bl      HexDump         /* should print out a bit field covering:
                                   00 00 00 16 */
        /* *** test end *** */

        /* Turn on all usr leds to indicate that we have reached this point,
           just before the dummy loop */
        mov     r0, #0xF
        bl      GPIO_TurnOnUsrLed

        /* Just a dummy loop; give the poor processor something to do, 
           cheerio and thanks for the fish... */

loop$:
        mov     r0, #1
        mov     r1, #15
        add     r2, r1, r0
        mov     r0, r2
        b       loop$


        /*********************************************************************** 
         * .section .rodata
         *
         **********************************************************************/
        .section .rodata
        .align 2
helloWorld$:
        .asciz "Hello world!\n\r"
        .align 2

        /*********************************************************************** 
         * .section .data
         *
         **********************************************************************/
        .section .data
        .align 2
tempString:
        .ascii "--------------------------------"
        .align 2





