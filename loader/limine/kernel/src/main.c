#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <limine.h>

__attribute__((used, section(".limine_requests")))
static volatile uint64_t limine_base_revision[] = LIMINE_BASE_REVISION(6);

__attribute__((used, section(".limine_requests")))
static volatile struct limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0
};

__attribute__((used, section(".limine_requests")))
static volatile struct limine_memmap_request memmap_request = {
    .id = LIMINE_MEMMAP_REQUEST_ID,
    .revision = 0
};

__attribute__((used, section(".limine_requests_start")))
static volatile uint64_t limine_requests_start_marker[] = LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".limine_requests_end")))
static volatile uint64_t limine_requests_end_marker[] = LIMINE_REQUESTS_END_MARKER;

static void hcf(void) {
    for (;;) {
        asm ("hlt");
    }
}

void LimineLoader_static_load_static_0(void);
void LimineLoader_post_init_static_0(void);
void LimineLoader_set_static_framebuffer_static_3(void*, int, int);
void LimineLoader_set_static_memory_map_static_2(void*, int);
void SystemFont_populate_font_static_1(const char*);

extern const char fontdata_8x16[4096];

extern void LimineLoader_halt_program_static_0() {
    hcf();
}

extern void Paging_set_page_address_static_1(void *address) {
    __asm__ volatile (
        "mov %0, %%cr3"
        :
        : "r"((uintptr_t)address)
        : "memory"
    );
}

void kmain(void) {
    if (LIMINE_BASE_REVISION_SUPPORTED(limine_base_revision) == false) {
        hcf();
    }

    if (framebuffer_request.response == NULL
     || framebuffer_request.response->framebuffer_count < 1) {
        hcf();
    }

    SystemFont_populate_font_static_1(fontdata_8x16);

    LimineLoader_static_load_static_0();

    for (uint64_t i = 0; i < framebuffer_request.response->framebuffer_count; i++) {
        struct limine_framebuffer *framebuffer = framebuffer_request.response->framebuffers[i];

        if (framebuffer->memory_model != LIMINE_FRAMEBUFFER_RGB || framebuffer->bpp != 32) {
            hcf();
        }

        LimineLoader_set_static_framebuffer_static_3(framebuffer->address, framebuffer->width, framebuffer->height);
    }

    if (memmap_request.response->entry_count == 0)
      hcf();

    LimineLoader_set_static_memory_map_static_2(memmap_request.response->entries, memmap_request.response->entry_count);

    LimineLoader_post_init_static_0();

    hcf();
}
