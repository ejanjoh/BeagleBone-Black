/******************************************************************************
 *  misc.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-12-03
 *
 *  Reference: 
 *
 ******************************************************************************/


        /*********************************************************************** 
         * ItoA32_Hex
         *
         * Convert an integer value to a null-terminated string with the base
         * 16. The hexadicimal part is written as capital letters. A result
         * would be on the form 0x00FF00FF. All 32 bites are included even if 
         * they are zeros and all result consist of 11 chars (bytes) included 
         * the null-termination. No error correction exists.
         *
         * C prototype: void ItoA32_Hex(uint32_t val, char *str) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global ItoA32_Hex
ItoA32_Hex:

        int     .req r0             /* integer value (int) */
        ptr     .req r1             /* pointer to string (ptr) */
        chr     .req r2             /* character (chr) */
        cnt     .req r3             /* counter (cnt) */

        mov     chr, #'0'
        strb    chr, [ptr]
        mov     chr, #'x'
        strb    chr, [ptr, #1]!
        mov     cnt, #0

1:
        mov     chr, int
        lsr     chr, chr, #28
        cmp     chr, #9
        bhi     3f

2:      /* digit in range [0, 9] */
        add     chr, chr, #48
        b       4f

3:      /* digit in range [A, F] */
        add     chr, chr, #('A' - 10)

4:
        strb    chr, [ptr, #1]!
        lsl     int, int, #4
        add     cnt, cnt, #1

        cmp     cnt, #8
        beq     10f
        b       1b

10:
        mov     chr, #0
        strb    chr, [ptr, #1]!

        .unreq  int
        .unreq  ptr
        .unreq  chr
        .unreq  cnt

        mov     pc, lr


        /*********************************************************************** 
         * HexDump
         *
         * Dump the content of a region in memory (memory or memory mapped
         * registers). The function prints out the word at address "addr" and 
         * the following (nbr - 1) words. The output is availible as hex values. 
         * No check is performed on the first in parameter "addr".
         *
         * C prototype: void HexDump(uint32_t addr, uint32_t nbr) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global HexDump
HexDump:
        stmfd   sp!, {fp, lr}

        /* Local variables 
        fp + 4:     16 bits to store the ascii repr. for the address
        fp + 20:    16 bits to store the ascii repr. for the value in hex
        */
        sub     sp, sp, #36
        mov     fp, sp

        addr    .req r2             /* the address */
        endAddr .req r3             /* the last address to be read */

        cmp     r1, #0
        beq     100f

        mov     addr, r0
        add     endAddr, addr, r1, lsl #2
        
1:
        /* the address */
        mov     r0, addr
        add     r1, fp, #4
        stmfd   sp!, {r2, r3}
        bl      ItoA32_Hex
        ldmfd   sp!, {r2, r3}

        /* the content at addr */
        ldr     r0, [addr], #4
        add     r1, fp, #20
        stmfd   sp!, {r2, r3}
        bl      ItoA32_Hex
        /*ldmfd   sp!, {r2, r3}             done below... */

        /* print out... */

        /* ...the address */
        add     r0, fp, #4
        mov     r1, #16
        bl      UART_PutString

        /* ...the first space */
        ldr     r0, =HEXDUMP_SPACE1
        mov     r1, #7
        bl      UART_PutString

        /* ...the content at addr */
        add     r0, fp, #20
        add     r0, r0, #2
        mov     r1, #2
        bl      UART_PutString
        mov     r0, #' '
        bl      UART_PutChar

        add     r0, fp, #20
        add     r0, r0, #4
        mov     r1, #2
        bl      UART_PutString
        mov     r0, #' '
        bl      UART_PutChar

        add     r0, fp, #20
        add     r0, r0, #6
        mov     r1, #2
        bl      UART_PutString
        mov     r0, #' '
        bl      UART_PutChar

        add     r0, fp, #20
        add     r0, r0, #8
        mov     r1, #2
        bl      UART_PutString

        /* ...the endl */
        ldr     r0, =HEXDUMP_ENDL
        mov     r1, #3
        bl      UART_PutString

        ldmfd   sp!, {r2, r3}

        /* are we done? */
        cmp     addr, endAddr
        blo     1b

100:
        .unreq  addr
        .unreq  endAddr

        add     sp, sp, #36
        ldmfd   sp!, {fp, pc}


        /*********************************************************************** 
         * Div32
         *
         * Perform a 32 bit integer division, using binary long division. No 
         * error handling will be performed, however when divided by zero the 
         * function will return 0xFFFFFFFF and it's up to the user to detect 
         * this.
         *
         * C prototype: uint32_t Div32(uint_32 dividend, uint_32 divisor) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global Div32
Div32:
        stmfd   sp!, {r4, lr}
        mov     r2, r0

        res     .req r0         /* result of division                       */
        div     .req r1         /* divisor                                  */
        rem     .req r2         /* reminder, initially reminder = dividend  */
        iter    .req r3         /* iterate                                  */
        temp    .req r4         /* temporary                                */

        /* if dividend is equal to zero */
        cmp     rem, #0
        moveq   res, #0
        beq     100f

        /* if divisor is equal to zero */
        cmp     div, #0
        ldreq   res, =0xffffffff
        beq     100f

        /* if dividend equal to divisor */
        cmp     div, rem
        moveq   res, #1
        beq     100f

        /* if dividend is less then divisor */
        cmp     rem, div
        movls   res, #0
        bls     100f
        
        mov     res, #0
        mov     iter, #0
        mov     temp, #0

        clz     iter, div               /* leading zeros on the divisor */
        clz     temp, rem               /* leading zeros on the dividend */
        sub     iter, iter, temp
        lsl     div, div, iter
        add     iter, iter, #1

1:
        /* if reminder >= divisor then */
        cmp     rem, div
        subhs   rem, rem, div
        addhs   res, res, #1

        /* are we done? */
        sub     iter, iter, #1
        cmp     iter, #0
        beq     100f

        /* next... */
        lsr     div, div, #1
        lsl     res, res, #1
        b       1b

100:
        .unreq  res
        .unreq  div
        .unreq  rem
        .unreq  iter
        .unreq  temp

        ldmfd   sp!, {r4, pc}


        /*********************************************************************** 
         * .section .rodata
         *
         **********************************************************************/
        .section .rodata
        .align 2

HEXDUMP_SPACE1:
        .asciz ":     "
        .align 2

HEXDUMP_ENDL:
        .asciz "\n\r"
        .align 2







