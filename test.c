#include "test.h"

// Check if a large stack frame can be allocated.
void test_large_frame_alloc(void) {
    volatile uint32_t pad[256] = {0};
}

// Check if stack arguments are properly copied.
void test_stack_arg(uint32_t reg_arg0, uint32_t reg_arg1,
                    uint32_t reg_arg2, uint32_t reg_arg3,
                    uint32_t stk_arg0, uint32_t stk_arg1,
                    uint32_t stk_arg2, uint32_t stk_arg3) {
    volatile uint32_t pad[4] = {0};

    if (stk_arg0 != STK_ARG0_VAL || stk_arg1 != STK_ARG1_VAL
        || stk_arg2 != STK_ARG2_VAL || stk_arg3 != STK_ARG3_VAL)
        while (1);
}

// Check if return values in registers (r0 and r1) are
// properly passed back to the caller.
uint64_t test_reg_ret(void) {
    volatile uint32_t pad[4] = {0};
    return REG_RET_VAL;
}

// Check if returning struct is properly written back
// to the caller's stacklet.
struct StackRetVals test_stack_ret(void) {
    struct StackRetVals vals = {
        .vals = {
            STK_RET_VAL0,
            STK_RET_VAL1,
            STK_RET_VAL2,
            STK_RET_VAL3
        }
    };
    return vals;
}

// A recursive implementation calculating fibonacci number.
static uint32_t recur_fib(uint32_t x) {
    volatile uint32_t a, b;
    if (x <= 2) return 1;
    a = recur_fib(x - 1);
    b = recur_fib(x - 2);
    return a + b;
}

// Check if fibonacci number is correctly calculated.
void test_fibonacci(void) {
    uint32_t a = 0, b = 1;
    for (uint32_t x = 1; x <= 20; ++x) {
        uint32_t c = a + b;
        a = b;
        b = c;
        if (a != recur_fib(x))
            while (1);
    }
}
