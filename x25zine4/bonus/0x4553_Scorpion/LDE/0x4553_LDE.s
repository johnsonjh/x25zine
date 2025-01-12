/*
*
*       ____| |           |                  _)       ___|              |
*       __|   |  _ \  __| __|  __| _ \  __ \  |  __|\___ \   _ \  |   | |  __|
*       |     |  __/ (    |   |   (   | |   | | (         | (   | |   | |\__ \
*      _____|_|\___|\___|\__|_|  \___/ _|  _|_|\___|_____/ \___/ \____|_|____/
*      	    
*        			    Presents
*
*		[ 0x4553_LDE - 16/32-bit Length Disassembler Engine ]
*		
*					    (c) Ares, 2003
*					    
*[-----------------------------------------------------------------------------------]
*  Description:
* It based on ADE32 disassembler engine by z0mbie, modified and ported to AT&T asm.
*
* table.h - contain table of opcodes from 0x00 to 0xFF, 
* it define the type of each other.
* 
*  Usage:
* There is the main function l_disasm(). It get one parameter from stack, 
* which point to array with data. Return value reside in %eax - length of opcode.
*
*  Example:
* ...
* mov data,%eax		
* add $123,%eax		# data[123]
* push %eax
* call l_disasm
* ...
*
* Section Headers:
*    [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
*    [ 0]                   NULL            00000000 000000 000000 00      0   0  0
*    [ 1] .text             PROGBITS        08048074 000074 0002a5 00  AX  0   0  4
*    [ 2] .data             PROGBITS        08049380 000380 000800 00  WA  0   0  4
*    ...
*                                                           = AA5(hex) = 2725(dec)	
*
*[-----------------------------------------------------------------------------------]
*
* version: 1.0BETA
*
*/

.include "LDE/table.h"
.text
# little defines
diza = 12
buffer = -4
flag1 = -52
flag2 = -51
opcode = -53
t = -60
mod = -61
rm = -62
a = -68
b = -72 
counter = -76

.globl l_disasm
l_disasm:
	pushl %ebp
	movl %esp,%ebp
	sub $280,%esp
	movl 8(%ebp),%eax		
	movl %eax,buffer(%ebp)		# buf
	leal -48(%ebp),%eax		# temp diza structure
	movl %eax,diza(%ebp)		# diza

	movb $4,1(%eax)                 # filling structure
	movb $4,(%eax)

	movl $0,flag1(%ebp)		# flag1 = 0

loop:
	movl buffer(%ebp),%eax
	movb (%eax),%dl
	movb %dl,opcode(%ebp)		# opcode
	incl buffer(%ebp)		# buf++;
	movzbl opcode(%ebp),%eax	 
	leal 0(,%eax,4),%edx
	movl $op_tab,%eax
	movl (%edx,%eax),%edx
	movl %edx,t(%ebp)		# t = op_tab[opcode]
	movb t(%ebp),%al
	andb $0xF8,%al
	testb %al,%al
	je check_opcode
	movl flag1(%ebp),%eax
	andl t(%ebp),%eax
	testl %eax,%eax
	jne return

	movl t(%ebp),%edx
	orl %edx,flag1(%ebp)

# prefix/mod/rm/flags/opcodes...checking
# no reason to comment all this stuff...

check_prefix:

	movb t(%ebp),%al
	test %esi,%esi
	jne chp1
	andb $0x10,%al
	testb %al,%al
	je chp1
	jmp chpn
chp1:
	movb t(%ebp),%al
	incl %esi
	andb $0x20,%al
	testb %al,%al
	je cp_sub2
chpn:
	movl diza(%ebp),%eax
	movl diza(%ebp),%edx
	movb 1(%edx),%cl
	xorb $6,%cl
	movb %cl,1(%eax)
	jmp loop

cp_sub2:
	movb t(%ebp),%al
	andb $0x80,%al
	testb %al,%al
	je cp_sub3
        movl diza(%ebp),%eax
	movb opcode(%ebp),%dl
	movb %dl,21(%eax)
	jmp loop

cp_sub3:
	movb t(%ebp),%al
	andb $0x40,%al
	testb %al,%al
	je loop
	movl diza(%ebp),%eax
	movb opcode(%ebp),%dl
	movb %dl,20(%eax)

check_opcode:
	movl t(%ebp),%eax
	orl %eax,flag1(%ebp)
	movl diza(%ebp),%eax
	movb opcode(%ebp),%dl
	movb %dl,22(%eax)
	cmpb $15,opcode(%ebp)
	jne co_sub1
	movl buffer(%ebp),%ebx
	movb (%ebx),%al
	movb %al,opcode(%ebp)
	incl buffer(%ebp)
	movl diza(%ebp),%eax
	movb opcode(%ebp),%dl
	movb %dl,23(%eax)
	movzbl opcode(%ebp),%eax
	leal 256(%eax),%edx
	leal 0(,%edx,4),%eax
	movl $op_tab,%edx
	movl (%eax,%edx),%ecx
	orl %ecx,flag1(%ebp)
	cmpl $-1,flag1(%ebp)
	jne check_mod
	jmp return

co_sub1:
	cmpb $0xF7,opcode(%ebp)
	jne co_sub2
	movl buffer(%ebp),%eax
	movb (%eax),%dl
	andb $0x38,%dl
	testb %dl,%dl
	jne check_mod
	orb $0x20,flag2(%ebp)
	jmp check_mod

co_sub2:
	cmpb $0xF6,opcode(%ebp)
	jne check_mod
	movl buffer(%ebp),%eax
	movb (%eax),%dl
	andb $0x38,%dl
	testb %dl,%dl
	jne check_mod
	orb $1,flag2(%ebp)

check_mod:
	movl flag1(%ebp),%eax
	andl $0x4000,%eax
	testl %eax,%eax
	je checks_complete
	movl buffer(%ebp),%edi
	movb (%edi),%al
	movb %al,opcode(%ebp)
	incl buffer(%ebp)
	movl diza(%ebp),%eax
	movb opcode(%ebp),%dl
	movb %dl,24(%eax)
	movb opcode(%ebp),%al
	andb $0x38,%al
	cmpb $0x20,%al
	jne cm_sub1
	movl diza(%ebp),%eax
	cmpb $0xFF,22(%eax)
	jne cm_sub1
	orb $4,-50(%ebp)		# flag

cm_sub1:				
	movb opcode(%ebp),%al
	andb $0xC0,%al
	movb %al,mod(%ebp)
	movb opcode(%ebp),%dl
	andb $7,%dl
	movb %dl,rm(%ebp)
	cmpb $0xC0,mod(%ebp)
	je checks_complete
	movl diza(%ebp),%eax
	cmpb $4,(%eax)
	jne cm_sub5
	cmpb $4,rm(%ebp)
	jne cm_sub2
	orb $8,flag2(%ebp)
	movl buffer(%ebp),%edi
	movb (%edi),%al
	movb %al,opcode(%ebp)
	incl buffer(%ebp)
	movl diza(%ebp),%eax
	movb opcode(%ebp),%dl
	movb %dl,25(%eax)
	movb opcode(%ebp),%cl
	andb $7,%cl
	movb %cl,rm(%ebp)

cm_sub2:
	cmpb $0x40,mod(%ebp)
	jne cm_sub3
	orb $1,flag1(%ebp)
	jmp checks_complete

cm_sub3:
	cmpb $0x80,mod(%ebp)
	jne cm_sub4
	orb $4,flag1(%ebp)
	jmp checks_complete

cm_sub4:
	cmpb $5,rm(%ebp)
	jne checks_complete
	orb $4,flag1(%ebp)
	jmp checks_complete

cm_sub5:
	cmpb $0x40,mod(%ebp)
	jne cm_sub6
	orb $1,flag1(%ebp)
	jmp checks_complete

cm_sub6:
	cmpb $0x80,mod(%ebp)
	jne cm_sub7
	orb $2,flag1(%ebp)
	jmp checks_complete

cm_sub7:
	cmpb $6,rm(%ebp)
	jne checks_complete
	orb $2,flag1(%ebp)

checks_complete:
	movl diza(%ebp),%eax
	movl flag1(%ebp),%edx
	movl %edx,8(%eax)
	movl flag1(%ebp),%eax
	andl $7,%eax
	movl %eax,a(%ebp)

	movl flag1(%ebp),%edx
	andl $0x700,%edx
	shrl $8,%edx
	movl %edx,b(%ebp)
	movl flag1(%ebp),%eax
	andl $0x1000,%eax
	testl %eax,%eax
	je cc_sub1
	movl diza(%ebp),%eax
	movzbl (%eax),%edx
	addl %edx,a(%ebp)

cc_sub1:
	movl flag1(%ebp),%eax
	andl $0x2000,%eax
	testl %eax,%eax
	je cc_sub2
	movl diza(%ebp),%eax
	movzbl 1(%eax),%edx
	addl %edx,b(%ebp)
cc_sub2:
	movl diza(%ebp),%eax
	movl a(%ebp),%edx
	movl %edx,diza(%eax)
	movl diza(%ebp),%eax
	movl b(%ebp),%edx
	movl %edx,16(%eax)
	movl $0,counter(%ebp)
cc_sub3:
	movl counter(%ebp),%eax
	cmpl a(%ebp),%eax
	jnb cc_sub4
	movl diza(%ebp),%edx
	leal 28(%edx),%eax
	movl counter(%ebp),%edx
	movl buffer(%ebp),%ecx
	movl %ecx,(%edx,%eax)
	incl buffer(%ebp)
	incl counter(%ebp)
	jmp cc_sub3
cc_sub4:
	movl $0,counter(%ebp)
cc_sub5:
	movl counter(%ebp),%eax
	cmpl b(%ebp),%eax
	jnb cc_sub6
	movl diza(%ebp),%edx
	leal 36(%edx),%eax
	movl counter(%ebp),%edx
	movl buffer(%ebp),%ecx
	movl %ecx,(%edx,%eax)
	incl buffer(%ebp)
	incl counter(%ebp)
	jmp cc_sub5
cc_sub6:
	movl buffer(%ebp),%eax
	subl 8(%ebp),%eax

return:
	leave
	ret

