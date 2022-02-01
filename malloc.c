/**
 * A naive heap implementation to support
 * segmented stack (-fsplit-stack) on ARM EABI.
 *
 * Author: Zhiyao Ma <zhiyao.ma@yale.edu>.
 */

#include "stm32f407xx.h"

/**
 * Below shows the SRAM region layout:
 * 
 * |----------------------| 0x20020000 (SRAM end)
 * |      Boot Stack      |
 * |----------------------| 0x20018000 (heap end)
 * |         Heap         |
 * |----------------------| 0x20010000 (heap start)
 * |      Temp Stack      |
 * |----------------------|
 * | Extended Static Base |
 * |    See morestack.S   |
 * |----------------------| 0x20000000 (SRAM start)
 */

#define HEAP_START 0x20010000u
#define HEAP_END   0x20018000u
#define CHUNK_SIZE 32u
#define MAP_SIZE   ((HEAP_END - HEAP_START) / CHUNK_SIZE)

// Each byte is a boolean value, showing whether
// the corresponding chunk is allocated or free.
// 0: free
// 1: allocated
static uint8_t BYTE_MAP[MAP_SIZE] = {0};

// Stores the length of allocated blocks. For example,
// if block #7-#12 (all inclusive) are allocated through
// a single callto `__malloc()`, then LEN_MAP[7] is set to 6,
// because 12 - 7 + 1 == 6.
static uint32_t LEN_MAP[MAP_SIZE] = {0};

// Allocate a block equal or greater than the requested `size`.
// The function is marked with `no_split_stack` attribute
// because it is used for stacklet allocation to support
// segmented stack .
void __attribute__((no_split_stack)) *__malloc(uint32_t size) {
    if (size == 0) return 0;

    static uint32_t last_idx = 0;

    uint32_t chunk_need = (size + CHUNK_SIZE - 1) / CHUNK_SIZE;
    uint32_t chunk_found = 0;
    uint32_t cur_idx = last_idx;
    uint32_t cur_start = cur_idx;

    // Starting from the index we previously left off, search
    // until the end of the heap area to find a continuous
    // block that satisfies the requested size.
    while (cur_idx != MAP_SIZE && chunk_found != chunk_need) {
        if (!BYTE_MAP[cur_idx]) {
            ++chunk_found;
            ++cur_idx;
        }
        else {
            chunk_found = 0;
            ++cur_idx;
            cur_start = cur_idx;
        }
    }

    // If we reach the end of the heap area but still didn't
    // find enough continuous chunks, start from the beginning
    // and try again.
    if (chunk_found != chunk_need) {
        cur_idx = 0;
        cur_start = cur_idx;

        // Loop from the start until reaching the index
        // we previous left off.
        while (cur_idx != last_idx && chunk_found != chunk_need) {
            if (!BYTE_MAP[cur_idx]) {
                ++chunk_found;
                ++cur_idx;
            }
            else {
                chunk_found = 0;
                ++cur_idx;
                cur_start = cur_idx;
            }
        }
    }

    // If we find one large enough.
    if (chunk_found == chunk_need) {
        // Mark the byte map.
        for (uint32_t i = 0; i < chunk_need; ++i)
            BYTE_MAP[cur_start + i] = 1;

        // Record the allocation length.
        LEN_MAP[cur_start] = chunk_need;

        // Update the last visited index.
        last_idx = cur_start + chunk_need;

        return (void *)(HEAP_START + cur_start * CHUNK_SIZE);
    }

    // Otherwise return NULL.
    return 0;
}

// Free a block allocated by `__malloc()`.
// The function is marked with `no_split_stack` attribute
// because it is used to free stacklet to support segmented
// stack.
void __attribute__((no_split_stack)) __free(void *ptr) {
    // Calculate the starting chunk number.
    uint32_t cur_start = ((uint32_t) ptr - HEAP_START) / CHUNK_SIZE;

    // Retrieve the allocation length.
    uint32_t len = LEN_MAP[cur_start];

    // Mark the chunks as free.
    LEN_MAP[cur_start] = 0;
    for (uint32_t i = 0; i < len; ++i)
        BYTE_MAP[cur_start + i] = 0;
}
