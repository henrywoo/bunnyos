nasm -f bin bunny.asm -o KERNEL.BUN

ndisasm -o 0x7e00 KERNEL.BUN > disboot.asm
