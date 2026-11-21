.SUFFIXES:
.DELETE_ON_ERROR:

V2_WORKSPACE ?= .
V2_ENTRY     ?= main.v2

BUILD  := build
V2_LL  := $(BUILD)/cbos.ll
V2_OBJ := $(abspath $(BUILD)/cbos.v2.o)

V2_TARGET := --target=x86_64-unknown-none-elf
V2_CFLAGS := -O2 -g -ffreestanding -fno-pic -ffunction-sections -fdata-sections \
             -mno-red-zone -mno-mmx -mno-sse -mcmodel=kernel -Wno-override-module

LIMINE_DIR := loader/limine

.PHONY: all v2-llvm limine clean distclean
all: limine

.PHONY: FORCE
FORCE:
$(V2_LL).new: FORCE
	@mkdir -p $(BUILD)
	$(V2C) -w "$(V2_WORKSPACE)" -i "$(V2_ENTRY)" -o "$@"

$(V2_LL): $(V2_LL).new
	@if ! cmp -s $< $@ 2>/dev/null; then cp $< $@; echo "V2 IR updated"; fi
	@touch -c $@ 2>/dev/null || true

v2-llvm: $(V2_LL)

$(V2_OBJ): $(V2_LL)
	clang $(V2_TARGET) $(V2_CFLAGS) -c $< -o $@

limine: $(V2_OBJ)
	$(MAKE) -C $(LIMINE_DIR) V2_OBJ="$(V2_OBJ)"

limine-%: $(V2_OBJ)
	$(MAKE) -C $(LIMINE_DIR) V2_OBJ="$(V2_OBJ)" $*

clean:
	rm -rf $(BUILD)
	-$(MAKE) -C $(LIMINE_DIR) clean

distclean: clean
	-$(MAKE) -C $(LIMINE_DIR) distclean