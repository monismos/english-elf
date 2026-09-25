/* Test assembly - minimal working version */
.section .text
.globl _start

_start:
	/* Print "hello world\n" */
	movl $1, %eax
	movl $1, %edi
	leaq msg(%rip), %rsi
	movl $13, %edx
	syscall

	movl $60, %eax
	xorl %edi, %edi
	syscall

.section .data
msg: .ascii "hello world\n"