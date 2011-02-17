# write to hard disk
nasm boot_fd.asm -o boot.bin && \
dd if=boot.bin of=/mnt/hgfs/Rabbit/Bunny-0-flat.vmdk bs=512 count=1 conv=notrunc
