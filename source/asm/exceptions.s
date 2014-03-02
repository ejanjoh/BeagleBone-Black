/******************************************************************************
 *  exceptions.s
 *
 *  Jan Johansson (ejanjoh)
 *  2014-02-23
 *
 *  Reference: 
 *      (1) TI Reference Manual AM335x Cortex A8 Microprocessors
 *      (2) ARM ARMv7
 *
 ******************************************************************************/

# Default interrupt vector table on BBB

#Address    Exception       Content
#===============================================
#4030CE00h  Reserved        Reserved
#4030CE04h  Undefined       PC = [4030CE24h]
#4030CE08h  SVC             PC = [4030CE28h]
#4030CE0Ch  Pre-fetch abort PC = [4030CE2Ch]
#4030CE10h  Data abort      PC = [4030CE30h]
#4030CE14h  Unused          PC = [4030CE34h]
#4030CE18h  IRQ             PC = [4030CE38h]
#4030CE1Ch  FIQ             PC = [4030CE3Ch]
#
#4030CE20h  Reserved        20090h
#4030CE24h  Undefined       20080h
#4030CE28h  SVC             20084h
#4030CE2Ch  Pre-fetch abort Address of default pre-fetch abort handler
#4030CE30h  Data abort      Address of default data abort handler
#4030CE34h  Unused          20090h
#4030CE38h  IRQ             Address of default IRQ handler
#4030CE3Ch  FIQ             20098h

# ARM exception v.s. mode mapping

#ARM Exception              Mode            CPSR interrupt mask
#===========================================================
#Reset                      Supervisor      F = 1, I = 1
#Undefined Instruction      Undef                  I = 1
#Supervisor Call            Supervisor             I = 1
#Prefetch Abort             Abort                  I = 1
#Data Abort                 Abort                  I = 1
#Not Used                   HYP             -      -
#IRQ Interrupt              IRQ                    I = 1
#FIQ Interrupt              FIQ             F = 1, I = 1


    .equ    LOAD_ADDR_UNDEF_INSTR_EXC,  0x4030CE24
    .equ    LOAD_ADDR_SVC_EXC,          0x4030CE28
    .equ    LOAD_ADDR_PREF_ABRT_EXC,    0x4030CE2C
    .equ    LOAD_ADDR_DATA_ABRT_EXC,    0x4030CE30
    .equ    LOAD_ADDR_IRQ_INTR,         0x4030CE38
    .equ    LOAD_ADDR_FIQ_INTR,         0x4030CE3C




        /*********************************************************************** 
         * ExcInitExcVect
         *
         *  Initiate exception vectors. Change the default addresses loaded when
         *  an exception occur.
         *
         * C prototype: void ExcInitExcVect(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcInitExcVect
ExcInitExcVect:

        addr        .req r0
        excHandl    .req r1

        /* clear the A bit - enable asynchronous aborts */
        /*mrs     r2, cpsr
        bic     r2, r2, #(1 << 8)
        msr     cpsr, r1*/

        /* Undefined Instruction */
        movw    addr, #:lower16:LOAD_ADDR_UNDEF_INSTR_EXC
        movt    addr, #:upper16:LOAD_ADDR_UNDEF_INSTR_EXC
        movw    excHandl, #:lower16:ExcUndefHandl
        movt    excHandl, #:upper16:ExcUndefHandl
        str     excHandl, [addr]

        /* Supervisor Call */
        movw    addr, #:lower16:LOAD_ADDR_SVC_EXC
        movt    addr, #:upper16:LOAD_ADDR_SVC_EXC
        movw    excHandl, #:lower16:ExcSVCHandl
        movt    excHandl, #:upper16:ExcSVCHandl
        str     excHandl, [addr]

        /* Prefetch Abort */
        movw    addr, #:lower16:LOAD_ADDR_PREF_ABRT_EXC
        movt    addr, #:upper16:LOAD_ADDR_PREF_ABRT_EXC
        movw    excHandl, #:lower16:ExcPrefAbortHandl
        movt    excHandl, #:upper16:ExcPrefAbortHandl
        str     excHandl, [addr]

        /* Data Abort */
        movw    addr, #:lower16:LOAD_ADDR_DATA_ABRT_EXC
        movt    addr, #:upper16:LOAD_ADDR_DATA_ABRT_EXC
        movw    excHandl, #:lower16:ExcDataAbortHandl
        movt    excHandl, #:upper16:ExcDataAbortHandl
        str     excHandl, [addr]

        /* IRQ Interrupt */
        movw    addr, #:lower16:LOAD_ADDR_IRQ_INTR
        movt    addr, #:upper16:LOAD_ADDR_IRQ_INTR
        movw    excHandl, #:lower16:ExcSVCHandl
        movt    excHandl, #:upper16:ExcSVCHandl
        str     excHandl, [addr]

        /* FIQ Interrupt */
        movw    addr, #:lower16:LOAD_ADDR_FIQ_INTR
        movt    addr, #:upper16:LOAD_ADDR_FIQ_INTR
        movw    excHandl, #:lower16:ExcFIQHandl
        movt    excHandl, #:upper16:ExcFIQHandl
        str     excHandl, [addr]

        mov     pc, lr
        .unreq  addr
        .unreq  excHandl


         /*********************************************************************** 
         * ExcUndefHandl
         *
         *  Notification on a Undefined Instruction exception.
         *
         * C prototype: void ExcUndefHandl(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcUndefHandl
ExcUndefHandl:
        mov     r4, lr      /* save the return address */
        add     r0, pc, #28
        mov     r1, #100
        bl      UART_PutString

        mov     r0, r4
        bl      UART_PutHex32
        mov     r0, #'\n'
        bl      UART_PutChar
        mov     r0, #'\r'
        bl      UART_PutChar

        /* To be done: print out the stack... */

        /* forever */
0:
        b       0b

.asciz "Undefined Instruction Exception Handler\n\r lr_und = "
.align 2


         /*********************************************************************** 
         * ExcSVCHandl
         *
         *  Notification on a Supervisor Call.
         *
         * C prototype: void ExcSVCHandl(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcSVCHandl
ExcSVCHandl:
        mov     r4, lr      /* save the return address */
        add     r0, pc, #28
        mov     r1, #100
        bl      UART_PutString

        mov     r0, r4
        bl      UART_PutHex32
        mov     r0, #'\n'
        bl      UART_PutChar
        mov     r0, #'\r'
        bl      UART_PutChar

        /* To be done: print out the stack... */

        /* forever */
0:
        b       0b

.asciz "Supervisor Call Handler\n\r lr_svc = "
.align 2


         /*********************************************************************** 
         * ExcPrefAbortHandl
         *
         *  Notification on a Prefetch Abort exception.
         *
         * C prototype: void ExcPrefAbortHandl(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcPrefAbortHandl
ExcPrefAbortHandl:
        mov     r4, lr      /* save the return address */
        add     r0, pc, #28
        mov     r1, #100
        bl      UART_PutString

        mov     r0, r4
        bl      UART_PutHex32
        mov     r0, #'\n'
        bl      UART_PutChar
        mov     r0, #'\r'
        bl      UART_PutChar

        /* To be done: print out the stack... */

        /* forever */
0:
        b       0b

.asciz "Prefetch Abort Exception Handler\n\r lr_abt = "
.align 2


         /*********************************************************************** 
         * ExcDataAbortHandl
         *
         *  Notification on a Data Abort exception.
         *
         * C prototype: void ExcDataAbortHandl(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcDataAbortHandl
ExcDataAbortHandl:
        mov     r4, lr      /* save the return address */
        add     r0, pc, #28
        mov     r1, #100
        bl      UART_PutString

        mov     r0, r4
        bl      UART_PutHex32
        mov     r0, #'\n'
        bl      UART_PutChar
        mov     r0, #'\r'
        bl      UART_PutChar

        /* To be done: print out the stack... */

        /* forever */
0:
        b       0b

.asciz "Data Abort Exception Handler\n\r lr_abt = "
.align 2


         /*********************************************************************** 
         * ExcIRQHandl
         *
         *  Notification on a IRQ Interrupt.
         *
         * C prototype: void ExcIRQHandl(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcIRQHandl
ExcIRQHandl:
        mov     r4, lr      /* save the return address */
        add     r0, pc, #28
        mov     r1, #100
        bl      UART_PutString

        mov     r0, r4
        bl      UART_PutHex32
        mov     r0, #'\n'
        bl      UART_PutChar
        mov     r0, #'\r'
        bl      UART_PutChar

        /* To be done: print out the stack... */

        /* forever */
0:
        b       0b

.asciz "IRQ Interrupt Handler\n\r lr_irq = "
.align 2


         /*********************************************************************** 
         * ExcFIQHandl
         *
         *  Notification on a FIQ Interrupt.
         *
         * C prototype: void ExcFIQHandl(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ExcFIQHandl
ExcFIQHandl:
        mov     r4, lr      /* save the return address */
        add     r0, pc, #28
        mov     r1, #100
        bl      UART_PutString

        mov     r0, r4
        bl      UART_PutHex32
        mov     r0, #'\n'
        bl      UART_PutChar
        mov     r0, #'\r'
        bl      UART_PutChar

        /* To be done: print out the stack... */

        /* forever */
0:
        b       0b

.asciz "FIQ Interrupt Handler\n\r lr_fiq = "
.align 2












