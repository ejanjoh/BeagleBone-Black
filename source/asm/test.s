/*******************************************************************************
 *  test.s
 *
 *  Jan Johansson (ejanjoh)
 *  2014-01-21
 *
 *  Updated:
 *      - 
 *
 *  Reference: 
 *      -
 *
 *  Comment:  
 *           
 ******************************************************************************/
 
 
        /* DDR3 SDRAM 512 M start address */
        .equ    DDR3_SDRAM_START_ADDR,  0x80000000

        /* Stop at “DDR3_SDRAM_STOP_ADDR – 0x1”, i.e. after 512 M */
        .equ    DDR3_SDRAM_STOP_ADDR,   0xA0000000


         /********************************************************************** 
         * TestSDRAM
         *
         * Performs a linear test, a write and read test, to test that the 
         * DDR3 SDRAM is configured in a "proper" way. The test write the 
         * address of the first byte in every word in the SDRAM. When the SDRAM
         * is completely filled the test reads every word and make sure it has 
         * the correct values.
         *
         * Note: The check is testing all 512 M SDRAM and it take some time...
         *       The test is not complete in the sense that it prove that no
         *       issues excists; it only indicate that this shouldn't be the 
         *       case.
         *
         * C prototype: void TestSDRAM(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global TestSDRAM
TestSDRAM:
        addr    .req r0     /* address within DDR3 SDRAM */
        end     .req r1     /* end address within DDR3 SDRAM */
        val     .req r2     /* value read from DDR3 SDRAM */
        
        stmfd   sp!, {fp, lr}

        ldr     r0, =TEXT_3_TEST_SDRAM_START
        mov     r1, #80
        bl      UART_PutString
        
        /* Write values to the DDR3 SDRAM – fill every words with the first 
           bytes start address */
        ldr     r0, =TEXT_4_TEST_SDRAM_WRITE
        mov     r1, #80
        bl      UART_PutString        

        ldr     addr, =DDR3_SDRAM_START_ADDR
        ldr     end, =DDR3_SDRAM_STOP_ADDR
1:
        /*str     addr, [addr], #4*/
        str     addr, [addr]
        add     addr, addr, #4
        cmp     addr, end
        bne     1b
        
        /* Read and check values from the DDR3 SDRAM */
        stmfd   sp!, {r0, r1, r2}
        ldr     r0, =TEXT_5_TEST_SDRAM_READ
        mov     r1, #80
        bl      UART_PutString       
        ldmfd   sp!, {r0, r1, r2}
        ldr     addr, =DDR3_SDRAM_START_ADDR

10:
        ldr     val, [addr]
        cmp     addr, val
        bne     ERROR_TEST_SDRAM

        add     addr, addr, #4
        cmp     addr, end
        bne     10b
100:
        ldr     r0, =TEXT_6_TEST_SDRAM_OK
        mov     r1, #80
        bl      UART_PutString
101:
        .unreq  addr
        .unreq  end
        .unreq  val
        
        ldmfd   sp!, {fp, pc}
        
        /* Error – the value read is unexpected… */
ERROR_TEST_SDRAM:
        stmfd   sp!, {r4}
        mov     r4, r0
        ldr     r0, =TEXT_1_TEST_SDRAM_ERROR
        mov     r1, #80
        bl      UART_PutString
        ldr     r0, =TEXT_2_TEST_SDRAM_ERROR
        mov     r1, #80
        bl      UART_PutString
        
        mov     r0, r4
        mov     r1, #1
        bl      HexDump
        ldmfd   sp!, {r4}
        b       101b


         /********************************************************************** 
         * TraceNbr
         *
         * Print out the number given as argument. The output will be given as
         * an 8 digit hexadecimal number.
         *
         * C prototype: void TraceNbr(uint32_t nbr)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global TraceNbr
TraceNbr:
        stmfd   sp!, {fp, lr}

        /* Local variables 
        fp + 4:     16 bits to store the ascii repr. for the number
        */
        sub     sp, sp, #20
        mov     fp, sp
        
        add     r1, fp, #4
        bl      ItoA32_Hex
        
        ldr     r0, =TEXT_1_TRACENBR
        mov     r1, #0x10
        bl      UART_PutString
        
        add     r0, fp, #4
        mov     r1, #0x10
        bl      UART_PutString
        
        ldr     r0, =TEXT_2_TRACENBR
        mov     r1, #0x10
        bl      UART_PutString
      
        add     sp, sp, #20
        ldmfd   sp!, {fp, pc}
        

        /*********************************************************************** 
         * .section .rodata
         *
         **********************************************************************/
        .section .rodata
        .align 2
TEXT_1_TEST_SDRAM_ERROR:
        .asciz "Error - the value read is unexpected...\n\r"
        .align 2
TEXT_2_TEST_SDRAM_ERROR:
        .asciz "Printing the last address and word:\n\r"
        .align 2
TEXT_3_TEST_SDRAM_START:
        .asciz "Start a linear test of the DDR3 SDRAM, testing 512 M:\n\r"
        .align 2
TEXT_4_TEST_SDRAM_WRITE:
        .asciz "   - write 512 M\n\r"
        .align 2
TEXT_5_TEST_SDRAM_READ:
        .asciz "   - read 512 M\n\r"
        .align 2
TEXT_6_TEST_SDRAM_OK:
        .asciz "DDR3 SDRAM test completed...\n\r"
        .align 2
TEXT_1_TRACENBR:
        .asciz "Trace: "
        .align 2
TEXT_2_TRACENBR:
        .asciz "\n\r"
        .align 2
