org 0x7C00

; pointer macros

%define diskAccessPacket 0x500
%define diskAccessBlockCount 0x502
%define diskAccessOffset 0x504
%define diskAccessSegment 0x506
%define diskAccessLBALow 0x508
%define diskAccessLBAMid 0x50A
%define diskAccessLBAHigh 0x50C

; code

; set up the stack
XOR AX, AX
MOV SS, AX
MOV SP, 0x7C00

MOV WORD [diskAccessPacket], 0x0010 ; 1st byte = size of packet ; 2nd byte must be 00
MOV WORD [diskAccessBlockCount], 1
MOV WORD [diskAccessOffset], 0x1000
MOV WORD [diskAccessSegment], 0
MOV WORD [diskAccessLBALow], 1
MOV WORD [diskAccessLBAMid], 0
MOV WORD [diskAccessLBAHigh], 0

MOV SI, diskAccessPacket
MOV AH, 0x42
MOV DL, 0x80
INT 0x13

MOV SI, read_failed_string
JC _halt

MOV CX, 8
MOV SI, gpt_magic_num
MOV DI, 0x1000
REPE CMPSB

MOV SI, no_gpt_string
JNE _halt

;MOV WORD AX, [0x1054]
;MUL WORD [0x1050]
;MOV CX, 0x200
;DIV CX
MOV WORD [diskAccessBlockCount], 8;AX
MOV WORD [diskAccessOffset], 0x1200
MOV WORD [diskAccessLBALow], 2

MOV SI, diskAccessPacket
MOV AH, 0x42
MOV DL, 0x80
INT 0x13

MOV SI, read_failed_string
JC _halt

MOV AX, [0x1050]
MOV SI, 0x1200
check_partition:
	DEC AX

	PUSHA
	CMP AX, 0xFFFF
	MOV SI, no_charm_error
	JE _halt
	POPA

	MOV CX, 16
	MOV BX, SI
	MOV DI, charm_magic_num
	REPE CMPSB
	MOV SI, BX
	JE load
	ADD SI, [0x1054]
	JMP check_partition

; load flat binary.... SI points to the partition entry of our bootloader
load:
MOV WORD [diskAccessBlockCount], 64
MOV AX, [SI + 0x20]
MOV [diskAccessLBALow], AX
MOV [0xFFF8], AX
MOV AX, [SI + 0x22]
MOV [diskAccessLBAMid], AX
MOV [0xFFFA], AX
MOV AX, [SI + 0x24]
MOV [diskAccessLBAHigh], AX
MOV [0xFFFC], AX
MOV WORD [diskAccessSegment], 0x1000
MOV WORD [diskAccessOffset], 0

MOV SI, diskAccessPacket
MOV AH, 0x42
MOV DL, 0x80
INT 0x13

JMP 0x1000:0

_halt:
	CALL print
	MOV SI, error_string
	CALL print
	CLI
	_hlt:
		HLT
		JMP _hlt

print: ; before calling this function, move pointer to desired string in SI
	_loop:
		; print character
		LODSB
		OR AL, AL
		JZ _endprint ; end print when encountering null character
		MOV AH, 0x0A
		MOV BX, 0x000F
		MOV CX, 1
		INT 0x10
		; get cursor position
		MOV AH, 0x03 
		INT 0x10
		; set cursor position
		CMP DL, 80
		JNE _shiftcolumn
		INC DH
		XOR DL, DL
		JMP _setcursor
		_shiftcolumn:
		INC DL
		_setcursor:
		MOV AH, 0x02 
		INT 0x10
		JMP _loop
	_endprint:
	RET

newline:
	MOV AH, 0x03
	INT 0x10
	INC DH
	XOR DL, DL
	MOV AH, 0x02
	INT 0x10
	RET

%include "src/print.asm"

test_string:
		DB	" *** ", 0
boot_msg:
		DB	"succ", 0
no_gpt_string:
		DB	"bad gpt ", 0
no_charm_error:
		DB	"charm gone ", 0
read_failed_string:
		DB	"read error ", 0
error_string:
		DB	"oh no", 0
gpt_magic_num:
		DB	"EFI PART"		; GPT header magic number
charm_magic_num:
		DB	"PEANUTS AND SOAP"	; BIOS boot partition

times 510-($-$$) db 0
db 0x55
db 0xAA
