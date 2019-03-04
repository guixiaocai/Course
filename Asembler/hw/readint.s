.section .text
.globl _start
_start:
	call readint
	movl $1, %eax
	movl $0, %ebx
	int $0x80
.globl readint
.type readint, @function
readint:
	subl $8, %esp
	movl $1, %esi
	movl $3, %eax
	movl $1, %ebx
	leal (%esp), %ecx
	movl $1, %edx
	int $0x80
	movl (%esp), %ecx
	cmp $43, %ecx
	je .L2
	cmp $45, %ecx
	jne .L1
	movl $-1, %esi
	jmp .L2
.L1:
	movl (%esp), %ecx
	subl $48, %ecx
	movl %ecx, 4(%esp)
.L2:
	movl $3, %eax
	movl $1, %ebx
	leal (%esp), %ecx
	movl $1, %edx
	int $0x80
	movl (%esp), %ecx
	cmp $48, %ecx
	jb .L3
	cmp $57, %ecx
	ja .L3
	subl $48, %ecx
	movl 4(%esp), %edx
	imull $10, %edx
	addl %ecx, %edx
	movl %edx, 4(%esp)
	jmp .L2	
.L3:
	movl 4(%esp), %eax
	imull %esi, %eax
	addl $8, %esp
P:
	ret

