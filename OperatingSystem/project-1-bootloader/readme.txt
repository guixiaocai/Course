Project1 Bootloader
==============================
文件说明：

bootblock.s
引导程序，在任务 2 中完成填写打印代码， 在任务 3 中添加移动内核代码

bootblock
bootblock.s的可执行文件

kernel.c
内核入口代码，在任务3中调用 BIOS，输出字符串“HelloOS”

kernel
kernel.c的可执行文件

createimage.c
引导块工具代码，任务 4 中实现将 bootblock 和 kernel 结合为一个操作系统镜像

createimage
将createimage.c通过gcc编译得到，非原始createimage文件

image
任务4中生成的二进制镜像文件


其它文件未修改 