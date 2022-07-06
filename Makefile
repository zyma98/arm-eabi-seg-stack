.PHONY: all clean run debug gdb

all: image.bin

image.bin: main.o system_stm32f4xx.o startup_stm32f407vgtx.o morestack.o malloc.o memops.o test.o
	~/opt/llvm/bin/clang -O2 -nostdlib -mcpu=cortex-m4 --target=armv7em-none-eabi \
		main.o malloc.o system_stm32f4xx.o startup_stm32f407vgtx.o morestack.o \
		memops.o test.o \
		lib/libclang_rt.builtins-arm.a \
		-o image.bin \
		-mcpu=cortex-m4 -mthumb \
		-fno-zero-initialized-in-bss \
		-fuse-ld=lld \
		-Wl,--gc-sections \
		-Tlinkerscript.ld

malloc.o: malloc.c
	~/opt/llvm/bin/clang \
		-DSTM32F407xx -mfloat-abi=soft \
		-fsplit-stack -fropi -frwpi \
		-O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o malloc.o malloc.c

test.o: test.c test.h
	~/opt/llvm/bin/clang \
		-DSTM32F407xx -mfloat-abi=soft \
		-fsplit-stack -fropi -frwpi \
		-O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o test.o test.c

main.o: main.c
	~/opt/llvm/bin/clang \
		-DSTM32F407xx -mfloat-abi=soft \
		-fsplit-stack -fropi -frwpi \
		-O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o main.o main.c

system_stm32f4xx.o: system_stm32f4xx.h system_stm32f4xx.c
	~/opt/llvm/bin/clang \
		-DSTM32F407xx -mfloat-abi=soft \
		-fsplit-stack -fropi -frwpi \
		-O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o system_stm32f4xx.o system_stm32f4xx.c

startup_stm32f407vgtx.o: startup_stm32f407vgtx.s
	~/opt/llvm/bin/clang \
		-mfloat-abi=soft -O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o startup_stm32f407vgtx.o startup_stm32f407vgtx.s

morestack.o: morestack.S
	~/opt/llvm/bin/clang \
		-mfloat-abi=soft -O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o morestack.o morestack.S

memops.o: memops.S
	~/opt/llvm/bin/clang \
		-mfloat-abi=soft -O2 -nostdlib --target=armv7em-none-eabi \
		-mcpu=cortex-m4 \
		-fno-zero-initialized-in-bss \
		-c -o memops.o memops.S

clean:
	rm -f image.bin *.o

run: image.bin
	qemu-system-gnuarmeclipse \
		-cpu cortex-m4 -machine STM32F4-Discovery -nographic \
		-kernel image.bin

debug: image.bin
	qemu-system-gnuarmeclipse \
		-cpu cortex-m4 -machine STM32F4-Discovery -nographic \
		-kernel image.bin \
		-gdb tcp::3333 -S

gdb: image.bin
	arm-none-eabi-gdb -q image.bin
