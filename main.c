/**
 * Test ARM EABI support for -fsplit-stack.
 * Author: Zhiyao Ma <zhiyao.ma@yale.edu>.
 */

#include "stm32f407xx.h"
#include "test.h"

#define LEDDELAY 50000000

// Perform tests against segmented stack.
// If any test fails, it will jump to an endless loop.
static void __attribute__((noinline)) all_tests(void) {
    // Test 1: large stack frame allocation
    test_large_frame_alloc();

    // Test 2: passing arguments
    test_stack_arg(0, 0, 0, 0, STK_ARG0_VAL, STK_ARG1_VAL,
                        STK_ARG2_VAL, STK_ARG3_VAL);

    // Test 3: returning results in registers
    if (REG_RET_VAL != test_reg_ret())
        while (1);

    // Test 4: returning results through stack
    struct StackRetVals vals = {
        .vals = {
            STK_RET_VAL0,
            STK_RET_VAL1,
            STK_RET_VAL2,
            STK_RET_VAL3
        }
    };
    struct StackRetVals ret_vals = test_stack_ret();
    for (unsigned i = 0; i < 4; ++i)
        if (vals.vals[i] != ret_vals.vals[i])
            while (1);
    
    // Test 5: recursively calculate fibonacci number
    test_fibonacci();
}

// Run the tests and delay for a while by spinning.
static void __attribute__((noinline)) delay_and_test(volatile uint32_t s) {
    all_tests();
    for (; s > 0; --s);
}

int main(void) {
    /* main function adopted from:
     * https://github.com/fcayci/stm32f4-bare-metal/blob/99256dfe4b8630d707743d8917f326cf600c9eeb/projects/blinky/blinky.c
     * 
     * Original author: Furkan Cayci
     */

    /* Enable GPIOD clock (AHB1ENR: bit 3) */
    RCC->AHB1ENR |= (1U << 3);

    /* Make Pin 12 output (MODER: bits 25:24) */
    // Pin 12 controls the green LED
    // Each pin is represented with two bits on the MODER register
    // 00 - input (reset state)
    // 01 - output
    // 10 - alternate function
    // 11 - analog mode
    GPIOD->MODER &= ~(3U << 2*12);
    GPIOD->MODER |=  (1U << 2*12);

    while (1) {
        delay_and_test(LEDDELAY);

        // Toggle the green LED.
        // If all the tests are passed, the green LED
        // will endlessly alternate between on and off.
        GPIOD->ODR ^= (1U << 12);
    }

    return 0;
}
