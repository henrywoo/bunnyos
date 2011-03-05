#nasm -f bin kernel.asm -o KERNEL.BUN && \
nasm -f bin bunny.asm -o KERNEL.BUN && \
nasm -f bin boot_fd.asm -o boot.bun && \
dd if=boot.bun of=floppy.img bs=512 count=1 conv=notrunc && \
mount -o loop floppy.img /mnt/floppy/ &&\
cp -fv KERNEL.BUN /mnt/floppy  &&\
umount /mnt/floppy &&\
bochs -f bochsrc
#java -jar peter-bochs.jar bochs -f bochsrc
