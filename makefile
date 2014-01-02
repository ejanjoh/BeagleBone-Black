################################################################################
#
#       Autor:      Jan Johansson (ejanjoh)
#       Created:    2013-10-11
#       Updated:    2014-01-02
#
################################################################################

# Toolchain:
TOOLCHAIN       ?= ./../../tools/cross/linaro/gcc-arm-none-eabi-4_7-2013q3/bin/

ARM_AS          ?= $(TOOLCHAIN)arm-none-eabi-as
ARM_CC          ?= $(TOOLCHAIN)arm-none-eabi-gcc
ARM_LD          ?= $(TOOLCHAIN)arm-none-eabi-ld
ARM_OC          ?= $(TOOLCHAIN)arm-none-eabi-objcopy
ARM_OD          ?= $(TOOLCHAIN)arm-none-eabi-objdump

HEX_DUMP        ?= ./../../tools/hexdump
APPEND_HEAD     ?= ./../../tools/append_gp_header

# Main directories:
CROSS           = ./

# Subdirectories @ CROSS:
BUILD_FILES     = $(CROSS)build/
EXTRA           = $(CROSS)extra/
ASM_FILES       = $(CROSS)source/asm/
C_FILES         = $(CROSS)source/c/
HEADER_FILES    = $(CROSS)source/header/

# Linker script:
LINKER          = kernel.ld

# Output files:
IMAGE           = kernel.img
LIST            = kernel.list
MAP             = kernel.map
ELF             = kernel.elf
HEX             = kernel.hexdump.txt
MLO             = MLO
OBJ := $(patsubst $(ASM_FILES)%.s,$(BUILD_FILES)%.o,$(wildcard $(ASM_FILES)*.s))
OBJ += $(patsubst $(C_FILES)%.c,$(BUILD_FILES)%.o,$(wildcard $(C_FILES)*.c))

# Build flags:
#DEPENDFLAGS    := -MD -MP                                      <--- No
DEPENDFLAGS     :=
INCLUDES        := -I $(HEADER_FILES)
#BASEFLAGS      := -O2 -nostdlib -pedantic -pedantic-errors     <--- No
BASEFLAGS       := -nostdlib
BASEFLAGS       += -nostartfiles -ffreestanding -nodefaultlibs
BASEFLAGS       += -fno-builtin -fomit-frame-pointer -mcpu=cortex-a8
WARNFLAGS       := -Wall -Wextra -Wshadow -Wcast-align -Wwrite-strings
WARNFLAGS       += -Wredundant-decls -Winline
WARNFLAGS       += -Wno-attributes -Wno-deprecated-declarations
WARNFLAGS       += -Wno-div-by-zero -Wno-endif-labels -Wfloat-equal
WARNFLAGS       += -Wformat=2 -Wno-format-extra-args -Winit-self
WARNFLAGS       += -Winvalid-pch -Wmissing-format-attribute
WARNFLAGS       += -Wmissing-include-dirs -Wno-multichar
WARNFLAGS       += -Wredundant-decls -Wshadow
WARNFLAGS       += -Wno-sign-compare -Wswitch -Wsystem-headers -Wundef
WARNFLAGS       += -Wno-pragmas -Wno-unused-but-set-parameter
WARNFLAGS       += -Wno-unused-but-set-variable -Wno-unused-result
WARNFLAGS       += -Wwrite-strings -Wdisabled-optimization -Wpointer-arith
WARNFLAGS       += -Werror
ASFLAGS         := $(INCLUDES) $(DEPENDFLAGS) -D__ASSEMBLY__
CFLAGS          := $(INCLUDES) $(DEPENDFLAGS) $(BASEFLAGS) $(WARNFLAGS) -std=c99
CFLAGS          += --save-temps
LINKFLAGS       := --no-undefined

# Rule to make it all:
all : $(IMAGE) $(LIST)

# Rule to create the list file:
$(LIST) : $(ELF)
	$(ARM_OD) -D $(ELF) > $(LIST)

# Rule to create the target image file:
$(IMAGE) : $(ELF)
	$(ARM_OC) $(ELF) -O binary $(IMAGE)
	$(HEX_DUMP) $(IMAGE) > $(HEX)
	$(APPEND_HEAD) $(IMAGE) 0x402f0400 static_gp_header.bin
	$(HEX_DUMP) $(MLO) > mlo.hexdump.txt

# Rule to link the object files to an elf file:
$(ELF) : $(OBJ) $(LINKER)
	$(ARM_LD) $(LINKFLAGS) $(OBJ) -Map $(MAP) -o $(ELF) -T $(LINKER)

# Rule to compile the c-files:
$(BUILD_FILES)%.o : $(C_FILES)%.c
	$(ARM_CC) $(CFLAGS) -c $< -o $@
	-rm -f $(CROSS)*.o
	-mv    $(CROSS)*.i $(EXTRA)
	-mv    $(CROSS)*.s $(EXTRA)

# Rule to assembly the asm-files:
$(BUILD_FILES)%.o : $(ASM_FILES)%.s
	#$(ARM_CC) $(ASFLAGS) -c $< -o $@
	$(ARM_AS) -c $< -o $@

# Rule to clean up a previous build:
clean :
	-rm -f $(BUILD_FILES)*.o
	-rm -f $(BUILD_FILES)*.d
	-rm -f $(EXTRA)*.i
	-rm -f $(EXTRA)*.s
	-rm -f $(ELF)
	-rm -f $(IMAGE)
	-rm -f $(LIST)
	-rm -f $(MAP)
	-rm -f $(HEX)
	-rm -f $(MLO)
	-rm -f mlo.hexdump.txt



