.SUFFIXES:
.DELETE_ON_ERROR:

V2_WORKSPACE ?= .
V2_ENTRY     ?= main.v2

BUILD  := build
V2_LL  := $(BUILD)/cbos.ll
V2_OBJ := $(abspath $(BUILD)/cbos.v2.o)

# Must match the kernel's codegen flags (-mcmodel=kernel etc.)
V2_TARGET := --target=x86_64-unknown-none-elf
V2_CFLAGS := -O2 -g -ffreestanding -fno-pic -ffunction-sections -fdata-sections \
             -mno-red-zone -mno-mmx -mno-sse -mcmodel=kernel -Wno-override-module

LIMINE_DIR := loader/limine

.PHONY: all v2-llvm limine clean distclean
all: limine

# The V2 compiler traverses imports itself, so make can't know the dependency
# list. Always run it, but only replace the .ll if the output actually changed,
# so unchanged builds don't recompile/relink.
.PHONY: FORCE
FORCE:
$(V2_LL).new: FORCE
	@mkdir -p $(BUILD)
	$(V2C) -w "$(V2_WORKSPACE)" -i "$(V2_ENTRY)" -o "$@"

$(V2_LL): $(V2_LL).new
	@if ! cmp -s $< $@ 2>/dev/null; then cp $< $@; echo "V2 IR updated"; fi
	@touch -c $@ 2>/dev/null || true

# Convenience: just emit the .ll
v2-llvm: $(V2_LL)

$(V2_OBJ): $(V2_LL)
	clang $(V2_TARGET) $(V2_CFLAGS) -c $< -o $@

# Hand the V2 object to the limine/kernel build; command-line variables
# propagate through sub-makes.
limine: $(V2_OBJ)
	$(MAKE) -C $(LIMINE_DIR) V2_OBJ="$(V2_OBJ)"

# Forward anything else (e.g. `make limine-run`  ->  `make -C loader/limine run`)
limine-%: $(V2_OBJ)
	$(MAKE) -C $(LIMINE_DIR) V2_OBJ="$(V2_OBJ)" $*

clean:
	rm -rf $(BUILD)
	-$(MAKE) -C $(LIMINE_DIR) clean

distclean: clean
	-$(MAKE) -C $(LIMINE_DIR) distclean