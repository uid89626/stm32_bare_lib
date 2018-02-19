# Makefile for all the examples in the STM32 Bare Library.

# Override this if you want to store temporary files outside of the source folder.
GENDIR := ./gen/

# Sub-directories holding generated files.
OBJDIR := $(GENDIR)/obj/
ELFDIR := $(GENDIR)/elf/
BINDIR := $(GENDIR)/bin/

# The cross-compilation toolchain prefix to use for gcc binaries.
CROSS_PREFIX := arm-none-eabi
AS := $(CROSS_PREFIX)-as
CC := $(CROSS_PREFIX)-gcc
LD := $(CROSS_PREFIX)-ld.bfd
OBJCOPY := $(CROSS_PREFIX)-objcopy

# Debug symbols are enabled with -g, but since we compile ELFs down to bin files, these don't
# affect the code size on-device.
CCFLAGS := -mcpu=cortex-m3 -mthumb -g

# We rely on headers from Arm's CMSIS library for things like device register layouts. To
# download the library, use `git clone https://github.com/ARM-software/CMSIS_5` in the parent
# folder of the one this Makefile is in (not this folder, but the one above).
CMSIS_DIR :=../CMSIS_5/
ifeq ($(shell test -d $(CMSIS_DIR) ; echo $$?), 1)
  $(error "CMSIS not found at '$(CMSIS_DIR)' - try 'git clone https://github.com/ARM-software/CMSIS_5 $(CMSIS_DIR)'")
endif

# Allow CMSIS core headers, and ones from this library.
INCLUDES := \
-isystem$(CMSIS_DIR)/CMSIS/Core/Include/ \
-I./include 

ASFLAGS :=

# Defines the offsets used when linking binaries for the STM32.
LDFLAGS := -T stm32_linker_layout.lds

# Rule used when no target is specified.
all: $(BINDIR)/examples/blink.bin $(BINDIR)/examples/hello_world.bin

clean:
	rm -rf $(GENDIR)

# Generic rules for generating different file types.
$(OBJDIR)%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CCFLAGS) $(INCLUDES) -c $< -o $@

$(OBJDIR)%.o: %.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $< -o $@

$(BINDIR)/%.bin: $(ELFDIR)/%.elf
	@mkdir -p $(dir $@)
	$(OBJCOPY) $< $@ -O binary

# Blink example rules.
# The boot.s file need to be first in linking order, since it has to be at the start of
# flash memory when the chip is reset.
BLINK_SRCS := source/boot.s \
$(wildcard examples/blink/*.c)
BLINK_OBJS := $(addprefix $(OBJDIR), \
$(patsubst %.c,%.o,$(patsubst %.s,%.o,$(BLINK_SRCS))))

# Link the blink example.
$(ELFDIR)/examples/blink.elf: $(BLINK_OBJS)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(BLINK_OBJS)

# Hello world example rules.
HELLO_WORLD_SRCS := source/boot.s \
$(wildcard examples/hello_world/*.c)
HELLO_WORLD_OBJS := $(addprefix $(OBJDIR), \
$(patsubst %.c,%.o,$(patsubst %.s,%.o,$(HELLO_WORLD_SRCS))))

$(ELFDIR)/examples/hello_world.elf: $(HELLO_WORLD_OBJS)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(HELLO_WORLD_OBJS)