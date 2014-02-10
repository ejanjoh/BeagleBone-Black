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

        /* Set up the stack pointer */
        ldr     sp, =__stack_top

        /* Zero out the bss, to be done... */

        /* Set up the interrupt vector table, to be done... */

        /* Set up the mux mapping needed. */
        bl      CtrlModMuxUART0

        /* Set up and initiate all PLLs and clocks needed by the system. */
        bl      ClockSetup

        /* Enable user leds (incl GPIO_EnableGPIO0) */
        bl      GPIO_EnableUsrLeds
        
        /* Turn on usr led 0 to indicate this point */
        mov     r0, #0x1
        bl      GPIO_TurnOnUsrLed
        
        /* Set baud rate, data bits etc needed by the UART for serial 
           communiction*/
        bl      UART_SetupSerialUART0

        /* Put something on UART0 */
        ldr     r0, =helloWorld$
        mov     r1, #0x20
        bl      UART_PutString

        /* Set up and configure the (L3) EMIF - DDR3 SDRAM */
        bl      Config_EMIF_DDR3_SDRAM

        /* Test the SDRAM - performs a linear test on the SDRAM */
        bl      TestSDRAM

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





