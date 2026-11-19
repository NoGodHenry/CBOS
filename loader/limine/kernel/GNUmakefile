.SUFFIXES:
.DELETE_ON_ERROR:

override OUTPUT := kernel
PREFIX := /usr/local

override CC := clang
TARGET := --target=x86_64-unknown-none-elf

CFLAGS := \
    -g -O2 -pipe \
    -Wall -Wextra \
    -std=gnu11 \
    -ffreestanding \
    -fno-common \
    -fno-stack-protector \
    -fno-pic \
    -ffunction-sections \
    -fdata-sections \
    -mno-red-zone \
    -mno-mmx \
    -mno-sse \
    -mcmodel=kernel

CPPFLAGS := \
    -nostdinc \
    -I src \
    -I limine-protocol/include \
    -isystem freestanding-c-hdrs/include \
    -MD -MP

NASMFLAGS := -f elf64 -g -F dwarf -i src/ -Wall

LDFLAGS := \
    -fuse-ld=lld \
    -Wl,--build-id=sha1 \
    -nostdlib \
    -static \
    -Wl,-z,max-page-size=0x1000 \
    -Wl,-z,noexecstack \
    -Wl,--gc-sections \
    -Wl,-T,linker-scripts/x86_64.lds \
    -Wl,-m,elf_x86_64

ifneq ($(filter-out clean distclean,$(or $(MAKECMDGOALS),default)),)
    ifeq ($(wildcard .deps-obtained),)
        $(error Please run the ./get-deps script first)
    endif
endif

# Absolute path to the V2-generated object, supplied by the root Makefile.
# Empty when building the loader standalone (then you get unresolved externs).
V2_OBJ ?=

SRCFILES := $(shell find -L src freestanding-lgrt/src -type f 2>/dev/null | LC_ALL=C sort)
CFILES := $(filter %.c,$(SRCFILES))
ASFILES := $(filter %.S,$(SRCFILES))
NASMFILES := $(filter %.asm,$(SRCFILES))

OBJ := \
    $(addprefix obj/,$(CFILES:.c=.c.o)) \
    $(addprefix obj/,$(ASFILES:.S=.S.o)) \
    $(addprefix obj/,$(NASMFILES:.asm=.asm.o))

HEADER_DEPS := \
    $(addprefix obj/,$(CFILES:.c=.c.d)) \
    $(addprefix obj/,$(ASFILES:.S=.S.d))

.PHONY: all clean distclean install uninstall
all: bin/$(OUTPUT)

-include $(HEADER_DEPS)

bin/$(OUTPUT): GNUmakefile linker-scripts/x86_64.lds $(OBJ) $(V2_OBJ)
	mkdir -p "$(dir $@)"
	$(CC) $(TARGET) $(LDFLAGS) $(OBJ) $(V2_OBJ) -o $@

obj/%.c.o: %.c GNUmakefile
	mkdir -p "$(dir $@)"
	$(CC) $(TARGET) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

obj/%.S.o: %.S GNUmakefile
	mkdir -p "$(dir $@)"
	$(CC) $(TARGET) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

obj/%.asm.o: %.asm GNUmakefile
	mkdir -p "$(dir $@)"
	nasm $(NASMFLAGS) -MD $(@:.o=.d) -MP $< -o $@

obj/src/memory.c.o obj/freestanding-lgrt/src/freestanding-lgrt.c.o: CFLAGS += -fno-lto

clean:
	rm -rf bin obj

distclean: clean
	rm -rf .deps-obtained .cache compile_commands.json \
	    freestanding-c-hdrs freestanding-lgrt limine-protocol

install: all
	mkdir -p "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)"
	cp bin/$(OUTPUT) "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)/"
	chmod 644 "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)/$(OUTPUT)"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)/$(OUTPUT)"
	-rmdir "$(DESTDIR)$(PREFIX)/share/$(OUTPUT)"