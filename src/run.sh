#nasm -f bin kernel.asm -o KERNEL.BUN && \
nasm -O5 -f bin bunny.asm -o bin/KERNEL.BUN && \
nasm -O5 -f bin boot_fd.asm -o bin/boot.bun && \
dd if=bin/boot.bun of=hw/floppy.img bs=512 count=1 conv=notrunc

if [ $? -eq 0 ];
then
  mount -o loop "hw/floppy.img" /mnt/floppy &&\
  cp -fv bin/KERNEL.BUN /mnt/floppy  &&\
  umount /mnt/floppy &&\
  \
  bochs -f bochsrc

fi
#java -jar peter-bochs.jar bochs -f bochsrc
