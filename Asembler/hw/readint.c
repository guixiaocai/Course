#include <stdio.h>

int readint() {
	int num;
	asm (
	"subl $8, %%esp\n\t"
	"movl $0, 4(%%esp)\n\t"
	"movl $1, %%esi\n\t"
	"movl $3, %%eax\n\t"
	"movl $1, %%ebx\n\t"
	"leal (%%esp), %%ecx\n\t"
	"movl $1, %%edx\n\t"
	"int $0x80\n\t"
	"xorl %%ecx, %%ecx\n\t"
	"movb (%%esp), %%cl\n\t"
	"cmp $43, %%ecx\n\t"
	"je .L2\n\t"
	"cmp $45, %%ecx\n\t"
	"jne .L1\n\t"
	"movl $-1, %%esi\n\t"
	"jmp .L2\n\t"
	".L1:\n\t"
	"subl $48, %%ecx\n\t"
	"movl %%ecx, 4(%%esp)\n\t"
	".L2:\n\t"
	"movl $3, %%eax\n\t"
	"movl $1, %%ebx\n\t"
	"leal (%%esp), %%ecx\n\t"
	"movl $1, %%edx\n\t"
	"int $0x80\n\t"
	"xorl %%ecx, %%ecx\n\t"
	"movb (%%esp), %%cl\n\t"
	"cmp $48, %%ecx\n\t"
	"jb .L3\n\t"
	"cmp $57, %%ecx\n\t"
	"ja .L3\n\t"
	"subl $48, %%ecx\n\t"
	"movl 4(%%esp), %%edx\n\t"
	"imull $10, %%edx\n\t"
	"addl %%ecx, %%edx\n\t"
	"movl %%edx, 4(%%esp)\n\t"
	"jmp .L2\n\t"	
	".L3:\n\t"
	"movl 4(%%esp), %%eax\n\t"
	"imull %%esi, %%eax\n\t"
	"movl %%eax, %0\n\t"
	"addl $8, %%esp"
	:"=m"(num)
	:
	);
	return num;	
}

int main() {
	int num;
	num = readint();
	printf("Read num = %d\n",num);
	return 0;
}

