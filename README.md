This is an implementation of segmented stack for ARM EABI.
- `morestack.S` is the runtime library containing the logic of allocating and freeing the stacklet and moving between stacklets.
- `malloc.c` is a naive heap implementation to support dynamic memory allocation.
- `memops.S` defines `mem*` library routines that meets the special requirement of using with segmented stack.
- `test.c` contains several tests for the segmented stack.

## Build Custom LLVM Toolchain

The LLVM backend and `ld.lld` are patched to support special function prologue generation. Clone the following patched version and build it.

```
git clone -b impl-seg-stack-arm-eabi https://github.com/ZhiyaoMa98/llvm-project.git
cd llvm-project

cmake -S llvm -B build -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX=~/opt/llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;lld" \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF

cd build
make # or make -jN     where N is the concurrent thread number
make install
```

## Install QEMU

The project targets STM32F407G-DISC1 board. Install the patched QEMU that supports it from https://xpack.github.io/qemu-arm/. The fastest way would be running the following commands.

```
sudo apt install npm
sudo npm install --global xpm@latest
xpm install --global @xpack-dev-tools/qemu-arm@latest --verbose
```

One can find the patched QEMU at
```
~/.local/xPacks/@xpack-dev-tools/qemu-arm/6.2.0-2.1/.content/bin/qemu-system-gnuarmeclipse
```

Add it to the PATH, or link it to `/usr/bin` as follows
```
sudo ln -s \
    ~/.local/xPacks/@xpack-dev-tools/qemu-arm/6.2.0-2.1/.content/bin/qemu-system-gnuarmeclipse \
    /usr/bin/qemu-system-gnuarmeclipse
```

## Run
`cd` to this repo. `make` to build. `make run` to run. Inside QEMU, `ctrl-a + x` to exit.

If everything is good, the green LED will alternate between on and off.

