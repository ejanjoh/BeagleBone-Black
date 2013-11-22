/******************************************************************************
 *	start.s
 *	
 *	Jan Johansson (ejanjoh)
 *	2013-11-07
 *
 *      Just a test...
 ******************************************************************************/

	/* ARM processor system modes */
	.equ	usr32_mode,	0b10000		/* user mode		*/
	.equ	sys32_mode,	0b11111		/* system mode		*/
	.equ	svc32_mode,	0b10011		/* supervisor mode	*/

/* Clock registers, see chapter 2 and 8 (AM335x TRM) */
/* Base */
	.equ	CM_WKUP, 0x44E00400 /* Clock Module Wakeup Registers    */

/* Offset */
	.equ	CM_WKUP_CLKSTCTRL, 0x0	/* 32 bit, base: CM_WKUP        */


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
	mov	r0, #sys32_mode
	mrs     r1, cpsr
	bic     r1, r1, #0x1F
	orr     r1, r1, r0
	msr     cpsr_c, r1

	/* Set up the stack */
	ldr     sp, =__stack_top

	/* Zero out the bss, tbd... */

	/* Set up the mux mapping */
	bl	CtrlModMuxUART0

	/* All relavant clocks are initiated by the ROM-code. The WKUP interface
	   clocks are always on, but the functional clocks must be enabled... */
	bl	GPIO_EnableUsrLeds
	bl	ClockEnableUART0

	/* Turn on usr led 0 to indicate this point */
	mov	r0, #0x1
	bl	GPIO_TurnOnUsrLed

	/* Set baud rate, data bits etc */
	bl	UART_SetupSerialUART0

	/* Put something on UART0 */
	ldr	r0, =helloWorld$
	mov	r1, #0x20
	bl	UART_PutString

	/* Turn on all usr leds to indicate that we have reached this point,
	   just before the dummy loop */
	mov	r0, #0xF
	bl	GPIO_TurnOnUsrLed

	/* Just a dummy loop; give the poor processor something to do, 
	   cheerio and thanks for the fish...*/
loop$:
	mov	r0, #1
	mov	r1, #15
	add	r2, r1, r0
	mov	r0, r2
	b	loop$


/*     *****************************************************************
       *** To be added							     */


	/* Initiate clocks on UART0 */
	bl	ClockInitPll

	/* Enforce that the PRCM is a up an running... */
	ldr	r4, =CM_WKUP
	mov	r6, #0x2
	str	r6, [r4, #CM_WKUP_CLKSTCTRL]

	/* Enable interface clock - GPIO0 */
	bl	ClockEnableGPIO0

/*     *****************************************************************
       *** Test								     */

	ldr	r0, =0x44E00400		/* = CM_WKUP */
	mov	r1, #0x00		/* = CM_WKUP_CLKSTCTRL */
	mov	r3, #0


	/* usr0 */
	ldr	r2, [r0, r1]
	and	r2, #(1 << 0)
	cmp	r2, #(1 << 0)
	bne	usr1
	add	r3, r3, #1

	/* usr1 */
usr1:
	ldr	r2, [r0, r1]
	and	r2, #(1 << 1)
	cmp	r2, #(1 << 1)
	bne	usr2
	add	r3, r3, #2

	/* usr2 */
usr2:
	ldr	r2, [r0, r1]
	and	r2, #(1 << 2)
	cmp	r2, #(1 << 2)
	bne	usr3
	add	r3, r3, #4

	/* usr3 */
usr3:
	ldr	r2, [r0, r1]
	and	r2, #(1 << 12)
	cmp	r2, #(1 << 12)
	bne	print
	add	r3, r3, #8

print:
	mov	r0, r3
	bl	GPIO_TurnOnUsrLed

/* ************************************************************************** */





	/*********************************************************************** 
	 * .section .rodata
	 *
	 **********************************************************************/
	.section .rodata
	.align 2
helloWorld$:
	.asciz "Hello world!\n\r\000????????????????????????????????"
	.align 2


