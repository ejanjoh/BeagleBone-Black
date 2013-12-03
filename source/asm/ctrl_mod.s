/******************************************************************************
 *  ctrl_mod.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-11-15
 *
 *  Reference: 
 *      - chapter 9 (AM335x TRM)
 *      - AM335x Data Sheet
 *
 ******************************************************************************/

/* CTRLMOD registers */
/* CTRLMOD Base */
    .equ    CTRLMODE,           0x44E10000      /* CTRLMOD register */

/* CTRLMOD Offset */
    .equ    CONF_UART0_RXD,     0x970           /* 32 bit, base CTRLMOD */
    .equ    CONF_UART0_TXD,     0x974           /* 32 bit, base CTRLMOD */


        /*********************************************************************** 
         * CtrlModMuxUART0
         *
         * Setup the mux for UART0.
         *
         * C prototype: void CtrlModMuxUART0(void)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global CtrlModMuxUART0
CtrlModMuxUART0:
        ldr     r0, =CTRLMODE
        mov     r2, #0                      /* Mux selected */
        and     r2, r2, #(1 << 3)           /* Pullup/pulldown disabled */
        and     r2, r2, #(1 << 4)           /* Pullup selected */

        /* Setup the mux for Rx */
        and     r2, r2, #(1 << 5)           /* Receiver enabled */
        str     r2, [r0, #CONF_UART0_RXD]

        /* Setup the mux for Tx */
        bic     r2, r2, #(1 << 5)           /* Receiver disabled */
        str     r2, [r0, #CONF_UART0_TXD]

        mov     pc, lr



