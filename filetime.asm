			title		filetime
			assume		cs:code, ss:s, ds:d

print		macro		string
			lea			dx, string
			mov			ah, 09
			int			21H
			endm

gtlin		macro		mes, string
			print		mes
			mov			ah, 0AH
			lea			dx, string
			int			21H
			lea			di, string+2			;DI = first symbol of msg
			mov			al, -1[di]				;AL = number of read symbols
			xor			ah, ah
			add			di, ax
			mov			[di], ah				;set null-terminator
			endm

s			segment		stack
			dw			128 dup (?)
s			ends

d			segment		
string		db			255, 0, 255 dup (?)
errmsg		db			'Error! Invalid character!', 0DH, 0AH, '$'
negflag		dw			?
fname		db			255, 0, 255 dup (?)
inhan		dw			?
outhan		dw			?
buf			db			256 dup (?)
delay		dw			?
msg1		db			'Enter the name of input file: $'
msg2		db			'Enter the name of output file: $'
msgd		db			'Enter the delay of processing: $'
ermsgo		db			'The file was not opened!$'
ermsgc		db			'The file was not created!$'
ermsgr		db			'Error reading the file$'
ermsgw		db			'Error writing the file$'
msgred		db			'Next symbol was processed', 0DH, 0AH, '$'
d			ends

code		segment
x			dw			?
old1c		dw			0,0
cr = 0DH
lf = 0AH
IntegerIn	proc
startp:		push		dx
			push		si
			push		bx

			mov			ah, 0AH
			lea			dx, string
			int			21H

			xor			ax, ax
			lea			si, string+2
			mov			negflag, ax
			cmp			byte ptr [si], '-'
			jne			m2

			not			negflag
			inc			si
			jmp			m
m2:			cmp			byte ptr [si], '+'
			jne			m
			inc			si
m:			cmp			byte ptr [si], cr
			je			exl
			cmp			byte ptr [si], '0'
			jb			err
			cmp			byte ptr [si], '9'
			ja			err

			mov			bx, 10
			mul			bx

			sub			byte ptr [si], '0'
			add			al, [si]
			adc			ah, 0

			inc			si
			jmp			m

err:		lea 		dx, errmsg
			mov			ah, 9
			int			21H
			jmp			startp

exl:		cmp			negflag, 0
			je			ex
			neg			ax

ex:			pop			bx
			pop			si
			pop			dx
			
			ret
IntegerIn	endp
NewLine		proc
			push		ax
			push		dx

			mov			ah, 02H
			mov			dl, 0AH
			int			21H

			mov			ah, 02H
			mov			dl, 0DH
			int			21H

			pop			dx
			pop			ax
			ret
NewLine		endp	

start:		mov			ax, d
			mov			ds, ax
			mov			ax, 351CH				;get interrupt vector 1c
			int			21h
			mov			word ptr cs:old1c, bx
			mov			word ptr cs:old1c+2, es
			mov			ax, 251CH
			lea			dx, tim					;set new interrupt 1c vector
			push		ds
			push		cs
			pop			ds						;25H ds has to be c segment 
			int			21h
			pop			ds						;get ds back

oread:		gtlin		msg1, fname
			mov			ah, 3DH
			lea			dx, fname+2
			xor			al, al					;AL = 0 => Access mode = read
			int			21H
			Call		NewLine
			jnc			mvinhnd					;check if carry flag was set - means there was an error
			print		ermsgo
			jmp			oread

mvinhnd:	mov			inhan, ax

cwrite:		gtlin		msg2, fname
			mov			ah, 3CH
			lea			dx, fname+2
			xor			cx, cx					;CX = 0 => not read-only, not hidden, not system, not a label, not a directory, not an archive
			int			21H
			Call		NewLine
			jnc			mvothnd
			print		ermsgc
			jmp			cwrite

mvothnd:	mov			outhan, ax

delent:		print		msgd
			Call		IntegerIn
			Call		NewLine
			mov			delay,	ax
			jmp			read_han

close_han:	mov			ah, 3EH
			mov			bx, inhan
			int			21H
			mov			ah, 3EH
			mov			bx, outhan
			int			21H
			push		ds
			mov			dx, word ptr cs:old1c
			mov			ds, word ptr cs:old1c + 2
			mov			ax, 251CH
			int			21H
			pop			ds
			mov			ah, 4CH
			int			21H

read_han:	mov			bx, inhan
			mov			ah, 3FH
			lea			dx, buf
			mov			cx, 256
			int			21H
			jnc			write_han
			print		ermsgr
			jmp			close_han

write_han:	cmp			ax, 0
			jz			close_han
			push		ax

			mov			cx, ax
			lea			si, buf
			mov			ax, delay
			mov			cs:x, ax
shift_l:	cmp			cs:x, 0
			jnz			shift_l
			mov			ax,  delay
			mov			cs:x, ax
			print		msgred		
			cmp			byte ptr [si], 'A'
			jb			skip

			cmp			byte ptr [si], 'Z'
			ja			skip

			mov			al, 32
			add			al, byte ptr [si]
			mov			byte ptr [si], al

skip:		inc			si
			loop		shift_l

			pop			cx
			mov			ah, 40H
			lea			dx, buf
			mov			bx, outhan
			int			21H

			jnc			read_han
			print		ermsgw
			jmp			close_han

tim:		pushf
			call 		dword ptr cs:old1c		;call the old interrupt handler
			sti									;allow external interrupts
			dec			cs:x
			iret
code		ends
			end			start
