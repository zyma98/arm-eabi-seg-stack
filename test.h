#ifndef TEST_H_
#define TEST_H_

#include <stdint.h>

#define STK_ARG0_VAL 0xdead
#define STK_ARG1_VAL 0xbeaf
#define STK_ARG2_VAL 0x8080ffff
#define STK_ARG3_VAL 0xaaaa0000

#define REG_RET_VAL  0x23336666abcd8888ULL

#define STK_RET_VAL0 7
#define STK_RET_VAL1 8
#define STK_RET_VAL2 9
#define STK_RET_VAL3 10

struct StackRetVals {
    uint32_t vals[4];
};

void test_large_frame_alloc(void);
void test_stack_arg(uint32_t reg_arg0, uint32_t reg_arg1,
                    uint32_t reg_arg2, uint32_t reg_arg3,
                    uint32_t stk_arg0, uint32_t stk_arg1,
                    uint32_t stk_arg2, uint32_t stk_arg3);

uint64_t test_reg_ret(void);
struct StackRetVals test_stack_ret(void);
void test_fibonacci(void);

#endif
