# Useful Links #

div ebx(eax must greater than ebx???)

http://freshmeat.net/projects/h2incn/

MIT Assembly Manual:
http://pdos.csail.mit.edu/6.828/2006/readings/i386/toc.htm

http://pdos.csail.mit.edu/pubs.html#Ph.D.+Theses

Write boot sector to thumb drive in windows:

```
dd if=boot.bin of=\\.\Volume{209afd32-3760-11e0-857e-002675378405} count=1
```


http://wiki.osdev.org/Main_Page

http://www.intel.com/products/processor/manuals/index.htm

http://blog.csdn.net/chobit_s/archive/2010/01/26/5259285.aspx

http://blog.csdn.net/voland/archive/2006/02/26/610084.aspx

http://blog.csdn.net/dog250/archive/2010/02/10/5303223.aspx

http://www.cnblogs.com/SuperXJ/archive/2011/01/15/1936104.html


http://code.google.com/p/peter-bochs/

http://en.skelix.org/skelixos/

http://www.huihoo.org/gnu_linux/own_os/booting-static_memory_layout_1.htm

http://duartes.org/gustavo/blog/category/software-illustrated

test and cmp: http://blog.csdn.net/yaojiank/archive/2009/12/19/5040742.aspx


PURE ASM OS:
http://www.menuetos.net/

http://xieyubo.spaces.live.com/blog/cns!55B39819C9DA4A2!282.entry

http://blog.csdn.net/tianxiangyuan/archive/2004/08/10/70546.aspx

jmp and retf??

IRETD 指令先弹出一个32位的EIP值，然后再弹出一个32位值并将最低的2个字节值传入CS寄存器，最后再弹出一个32位的标志寄存器值

在内核空间发生DB例外时的情况:中断发生时,依次将 EFLAGS,CS,EIP压入堆栈,然后进入中断程序(由于中断地址本来就在内核空间,所以不需要切换堆栈).在中断处理程序中作出相应的处理,然后使用 iretd 指令退出中断.( iretd 指令: 依次将堆栈弹出到 EIP,CS,EFLAGS),我们可以通过修改堆栈中EIP的值,在中断返回时跳转实现HOOK

interrupt: http://hi.baidu.com/gbslinux/blog/item/dc0ea23c772b0c3670cf6c2d.html

用   jmp   标号   这样的条转，标号与你当前的位置大于-127至+128   字节，就会出现这种现象。因为，汇编器默认的都是短条转。解决方法有二：一、将短条转改成长条转；二、将短条转的程序移到-127至+128   字节之间。


8042 keyboard programmable controller

http://blog.sina.com.cn/s/blog_4b45f83e010009be.html

http://www.cnblogs.com/gakusei/articles/1582145.html