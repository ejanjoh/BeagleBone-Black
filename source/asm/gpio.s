/******************************************************************************
 *  gpio.s
 *
 *  Jan Johansson (ejanjoh)
 *  2013-11-07
 *
 *  Reference: 
 *      - chapter 2 and 25 (AM335x TRM)
 *      - BeagleBone Black System Reference Manual
 *
 ******************************************************************************/


/* GPIO registers and defines */
/* GPIO Base */
    .equ    GPIO0,          0x44E07000  /* GPIO 0 reg */
    .equ    GPIO1,          0x4804C000  /* GPIO 1 reg */
    .equ    GPIO2,          0x481AC000  /* GPIO 2 reg */
    .equ    GPIO3,          0x481AE000  /* GPIO 3 reg */

/* GPIO Offset */
    .equ    GPIO_OE,            0x134   /* 32 bit, base GPIO0 to 3 */
    .equ    GPIO_CLEARDATAOUT,  0x190   /* 32 bit, base GPIO0 to 3 */
    .equ    GPIO_SETDATAOUT,    0x194   /* 32 bit, base GPIO0 to 3 */

/* GPIO Defines */
    .equ    GPIO1_21_USR_LED_0, 1<<21   /* table 7, BBB System Ref Man*/
    .equ    GPIO1_22_USR_LED_1, 1<<22   /* table 7, BBB System Ref Man*/
    .equ    GPIO1_23_USR_LED_2, 1<<23   /* table 7, BBB System Ref Man*/
    .equ    GPIO1_24_USR_LED_3, 1<<24   /* table 7, BBB System Ref Man*/
    .equ    GPIO_ALL_USR_LEDS,  0x1E00000



        /*********************************************************************** 
         * GPIO_EnableUsrLeds
         *
         * Enable the usage of the usr leds
         *
         * C prototype: void GPIO_EnableUsrLeds(void) 
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global GPIO_EnableUsrLeds
GPIO_EnableUsrLeds:
        stmfd   sp!, {lr}

        /* Enable clock for GPIO1 (usr leds) */
        bl      ClockEnableGPIO1

        /* Set the usr leds as output */
        ldr     r0, =GPIO1
        ldr     r1, [r0, #GPIO_OE]
        bic     r1, r1, #(GPIO_ALL_USR_LEDS)
        str     r1, [r0, #GPIO_OE]

        ldmfd   sp!, {pc}


        /*********************************************************************** 
         *  GPIO_TurnOnUsrLed
         *
         *  Turn on one or more user leds
         *
         *  in: r0:
         *      - b0001 usr led 0
         *      - b0010 usr led 1
         *      - b0100 usr led 2
         *      - b1000 usr led 3
         *
         * C prototype: void GPIO_TurnOnUsrLed(const uint32_t led)
         **********************************************************************/
        .section .text
        .code 32
        .align 2
        .global GPIO_TurnOnUsrLed
GPIO_TurnOnUsrLed:
        ldr     r1, =GPIO1

        and     r0, r0, #0xF
        cmp     r0, #0x0
        beq     100f

        lsl     r0, r0, #21
        str     r0, [r1, #GPIO_SETDATAOUT]

100:
        mov     pc, lr



