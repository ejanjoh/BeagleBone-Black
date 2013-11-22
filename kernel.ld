/******************************************************************************
*
*	Created by:		Jan Johansson 
*   Date:			2013-10-11
*	
******************************************************************************/

/*
 * Note: Some toolchains generate a initial underscore at all labels in the 
 * object files and it might cause that it’s not possible to access the labels 
 * in the linker script if not adjusted... 
 *
 * However, in this script the following naming convention are used for labels:
 * - no underscore for local labels
 * - one underscore for labels in the script on an out-sections level
 * - two underscores for labels in the script on an input-section level
 * - if not above, e.g. adjusted for some lib or so, it's commented...
 *   (all labels will be visible in the out section, use it with care (no local 
 *    will exist in reality using this toolchain...)
 */
 

heap_size 		= 0x1000;						/* heap size */
stack_size		= 0x1000;						/* stack size */


/* constitute the memory layout (memory map) for the system */
SECTIONS {

	/* @ address 0x0: interrupt vector table (ivt), size 8*4 byte */
	
	
	/* @ address 0x402f0400: start point of the system. */		
	. = 0x402f0400;
	_sections_start = .;

	/* section for basic setting-up of the system */
	_init_start = .;
	.init : {
		*(.init)
	}
	_init_end = .;

	/* section containing memory for dynamic allocation */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	_heap_start = .;
	.heap : {
		__heap_start = .;
		. = . + heap_size;
		__heap_end = .;
	}
	_heap_end = .;
	
	/* section containing all stacks for processes, as of now only one stack */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	_stack_start = .;
	.stack : {
		__stack_bottom = .;
		. = . + stack_size;
		__stack_top = .;
	}
	_stack_end = .;

	/* section containing all code in user and system mode after the basic initialization.
	   It also contains the code for exception handling. (and some "high level" initialization 
	   not done in the .init section) */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	_text_start = .;
	.text : {
		*(.text.startup)
		*(.text)
	}
	_text_end = .;

	/* (contains non-initialized data) */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	_bss_start = .;
	.bss : {
		*(.bss)
		*(COMMON)
	}
	. = ALIGN(0x4);			/* because we need to zero out the .bss at start-up and it needs to be word aligned */
	_bss_end = .;

	/* (contains read only data) */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	_rodata_start = .;
	.rodata : {
		*(.rodata)
		*(.rodata.str1.4)
	}
	_rodata_end = .;
	
	/* (contains initialized data) */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	_data_start = .;
	.data : {
		*(.data)
	}
	_data_end = .;
	
	/* Collect in-sections not trapped above */
	. = . + 4;					/* add a slack... */
	. = ALIGN(0x4);
	/DISCARD/ : {
		*(*)
	}
	
	_sections_end = .;
}


