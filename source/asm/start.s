/******************************************************************************
 *  start.s
 *
 *  Jan Johansson (ejanjoh)
 *  Date:       2013-11-07
 *  Updated:    2014-03-02
 *  
 ******************************************************************************/
 
#       ARM Modes              Encoding    Security state      Privilege level
#       ======================================================================
#       User            (usr)   10000       Both                PL0
#       FIQ             (fiq)   10001       Both                PL1
#       IRQ             (irq)   10010       Both                PL1
#       Supervisor      (svc)   10011       Both                PL1
#       Monitor         (mon)   10110       Secure only         PL1
#       Abort           (abt)   10111       Both                PL1
#       Hyp             (hyp)   11010       Non-secure          PL2
#       Undef           (und)   11011       Both                PL1
#       System          (sys)   11111       Both                PL1

        .equ    sys32_mode, 0b11111         /* system mode */
        
        /* Exception modes used */
        .equ    und32_mode, 0b11011         /* undefine mode */
        .equ    abt32_mode, 0b10111         /* abort mode */
        .equ    svc32_mode, 0b10011         /* supervisor mode */
        .equ    irq32_mode, 0b10010         /* interrupt mode */
        .equ    fiq32_mode, 0b10001         /* fast interrupt mode */
        
        /* DDR3 SDRAM 512 M start address */
        .equ    DDR3_SDRAM_START_ADDR,  0x80000000


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
        add     r10, pc, #-0x8      /* r10 = current load address */

        /* Assign a stack pointer to supervisor mode */
        movw    sp, #:lower16:__stack_svc_top
        movt    sp, #:upper16:__stack_svc_top

        /* Change to undefined mode */
        mov     r0, #und32_mode
        mrs     r1, cpsr
        bic     r1, r1, #0x1F
        orr     r1, r1, r0
        msr     cpsr_c, r1

        /* Assign a stack pointer to undefined mode */
        movw    sp, #:lower16:__stack_und_top
        movt    sp, #:upper16:__stack_und_top

        /* Change to abort mode */
        mov     r0, #abt32_mode
        mrs     r1, cpsr
        bic     r1, r1, #0x1F
        orr     r1, r1, r0
        msr     cpsr_c, r1

        /* Assign a stack pointer to abort mode */
        movw    sp, #:lower16:__stack_abt_top
        movt    sp, #:upper16:__stack_abt_top

        /* Change to irq mode */
        mov     r0, #irq32_mode
        mrs     r1, cpsr
        bic     r1, r1, #0x1F
        orr     r1, r1, r0
        msr     cpsr_c, r1

        /* Assign a stack pointer to irq mode */
        movw    sp, #:lower16:__stack_irq_top
        movt    sp, #:upper16:__stack_irq_top

        /* Change to fiq mode */
        mov     r0, #fiq32_mode
        mrs     r1, cpsr
        bic     r1, r1, #0x1F
        orr     r1, r1, r0
        msr     cpsr_c, r1

        /* Assign a stack pointer to fiq mode */
        movw    sp, #:lower16:__stack_fiq_top
        movt    sp, #:upper16:__stack_fiq_top

        /* Change to system mode */
        mov     r0, #sys32_mode
        mrs     r1, cpsr
        bic     r1, r1, #0x1F
        orr     r1, r1, r0
        msr     cpsr_c, r1

        /* Assign a stack pointer to system mode */
        movw    sp, #:lower16:__stack_sys_top
        movt    sp, #:upper16:__stack_sys_top

        /* Zero out the bss, needed if we would like to run C code... */
        movw    r0, #:lower16:_bss_start
        movt    r0, #:upper16:_bss_start
        mov     r1, #0
        movw    r2, #:lower16:_bss_end
        movt    r2, #:upper16:_bss_end
        sub     r2, r2, r0
        lsr     r2, r2, #2
        bl      MemSet32

        /* Enable the interrupt vector table */
        bl      ExcInitExcVect

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

        /* Put something on UART0 - the start address of the system */
        ldr     r0, =loadAddr
        mov     r1, #0x25
        bl      UART_PutString
        mov     r0, r10                 /* r10 = the start address */
        bl      UART_PutHex32
        ldr     r0, =lineEnd
        mov     r1, #0x5
        bl      UART_PutString

        /* Set up and configure the (L3) EMIF - DDR3 SDRAM */
        bl      Config_EMIF_DDR3_SDRAM

        /* Test the SDRAM - performs a linear test on the SDRAM */
        /*bl      TestSDRAM*/

        /* Test - check that the exceptions works as expected (svc call)...*/
        /*svc     #17*/
        
        /* Copy .text, .bss, .rodata, .data sections to the L3 SDRAM */
        movw    r0, #:lower16:_CPY_TO_L3_SDRAM_START
        movt    r0, #:upper16:_CPY_TO_L3_SDRAM_START
        mov     r1, #DDR3_SDRAM_START_ADDR        
        movw    r2, #:lower16:_CPY_TO_L3_SDRAM_END
        movt    r2, #:upper16:_CPY_TO_L3_SDRAM_END
        sub     r2, r2, r0
        lsr     r2, r2, #2
        bl      MemCopy32

        /* Turn on all usr leds to indicate that we have reached this point,
           just before the dummy loop */
        mov     r0, #0xF
        bl      GPIO_TurnOnUsrLed

        /*b       main*/            /* branch to main on public RAM */
        
        /* Calculate the offset of main on L3 SDRAM */
        movw    r0, #:lower16:main
        movt    r0, #:upper16:main
        movw    r1, #:lower16:_CPY_TO_L3_SDRAM_START
        movt    r1, #:upper16:_CPY_TO_L3_SDRAM_START
        sub     r0, r0, r1

        /* Move execution of main to L3 SDRAM */
        add     r0, r0, #DDR3_SDRAM_START_ADDR
        mov     pc, r0


        /*********************************************************************** 
         * main
         *
         * C prototype: void main(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global main
main:
        /* Print out the current address being executed */
        add     r10, pc, #-0x8      /* r10 = current load address */
        ldr     r0, =loadAddr
        mov     r1, #0x25
        bl      UART_PutString
        mov     r0, r10
        bl      UART_PutHex32
        ldr     r0, =lineEnd
        mov     r1, #0x5
        bl      UART_PutString

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
loadAddr:
        .asciz "Current load address: "
        .align 2
lineEnd:
        .asciz "\n\r"
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





