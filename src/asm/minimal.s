/* ENGLISH-ELF - Minimal working assembly compiler */
.section .text
.globl _start

_start:
	/* Just print "hello world" for now */
	mov $1, %rax
	mov $1, %rdi
	lea msg(%rip), %rsi
	mov $12, %rdx
	syscall
	
	/* Print newline */
	lea nl(%rip), %rsi
	mov $1, %rdx
	syscall
	
	/* Exit */
	mov $60, %rax
	xor %rdi, %rdi
	syscall

.section .data
msg: .ascii "hello world\n"
nl: .byte 10