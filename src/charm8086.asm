org 0

%define maxCommandLength 256

%define enterKeyScancode 0x0D
%define backspaceKeyScancode 0x08

%define currentDataSegment 0x1000

%define commandTableOffset 32768

_start:

XOR AX, AX
MOV SS, AX
MOV SP, 0xFFF0

MOV AX, 0xB000
MOV DS, AX
MOV ES, AX
MOV SI, 0x8000
MOV DI, 0x8000
MOV CX, 80
_paint_loop:
	LODSW
	MOV AX, 0xF000
	STOSW
	LOOP _paint_loop

MOV AX, currentDataSegment
MOV ES, AX
MOV DS, AX

PUSH DS
XOR AX, AX
MOV DS, AX
MOV AX, [DS:0xFFF8]
MOV CX, [DS:0xFFFA]
MOV DX, [DS:0xFFFC]
POP DS
MOV [DS:charmPartitionLbaLow], AX
MOV [DS:charmPartitionLbaMid], CX
MOV [DS:charmPartitionLbaHigh], DX

ADD AX, 64
ADC CX, 0
ADC DX, 0

MOV WORD [DS:diskAccessBlockCount], 64
MOV WORD [DS:diskAccessOffset], commandTableOffset
MOV WORD [DS:diskAccessSegment], currentDataSegment
MOV WORD [DS:diskAccessLbaLow], AX
MOV WORD [DS:diskAccessLbaMid], CX
MOV WORD [DS:diskAccessLbaHi], DX
CALL readBlock

PUSH SI
MOV SI, stringCommandTableError
JNC _commandTableRead
CALL printString
JMP __hang
_commandTableRead:
POP SI

MOV DI, commandString
CALL clear

readCommand:
	CALL getKeystroke
	CALL handleKeystroke
	JMP readCommand

executeCommand:
	CALL clear
	MOV DX, 0x0100
	CALL setCursor
	
	MOV SI, commandString
	MOV DI, commandHelp
	MOV CX, [DS:commandStringLength]
	REPE CMPSB
	JE _commandHelp
	
	CALL searchCommandTable
	OR AX, AX
	JZ _cmd_not_found
	MOV BX, AX
		
	_commandFound:
		MOV AX, [DS:charmPartitionLbaLow]
		MOV CX, [DS:charmPartitionLbaMid]
		MOV DX, [DS:charmPartitionLbaHigh]
		ADD AX, [DS:BX + 2]
		ADC CX, [DS:BX + 4]
		ADC DX, [DS:BX + 6]
		MOV WORD [DS:diskAccessBlockCount], 256
		MOV WORD [DS:diskAccessOffset], 0
		MOV WORD [DS:diskAccessSegment], 0x2000
		MOV WORD [DS:diskAccessLbaLow], AX
		MOV WORD [DS:diskAccessLbaMid], CX
		MOV WORD [DS:diskAccessLbaHi], DX	
		CALL readBlock
		JNC _doCommand
		MOV SI, stringIOError
		CALL printString
		JMP __hang
	
	_doCommand:
		PUSH DS
		PUSH ES
		MOV AX, 0x3000
		MOV DS, AX
		MOV ES, AX
		CALL 0x2000:0
		POP ES
		POP DS
		JMP _end_cmds
	
	_commandHelp:
		MOV SI, stringHelp
		CALL printString
		JMP _end_cmds
		
	_cmd_not_found:
		MOV SI, commandNotFoundMsg
		CALL printString
		CALL newline
		JMP _end_cmds
	
	_end_cmds:
		MOV DI, commandString
		MOV WORD [DS:commandStringLength], 0
		XOR DX, DX
		CALL setCursor
		JMP readCommand

handleKeystroke:
	CMP AL, enterKeyScancode
	JE executeCommand
	CMP AL, backspaceKeyScancode
	JE _do_backspace
	JMP _push_char
	
	_do_backspace:
		CMP DI, commandString
		JE _backspace_done
		DEC DI
		MOV AX, [DS:commandStringLength]
		DEC AX
		MOV [DS:commandStringLength], AX
		CALL backspace
		_backspace_done:
		RET
	
	_push_char:
		CALL printChar
		CMP DI, commandString + maxCommandLength
		JGE _handle_keystroke_ret
		STOSB
		MOV AX, [DS:commandStringLength]
		INC AX
		MOV [DS:commandStringLength], AX
		_handle_keystroke_ret:
		RET

; Returns pointer to matched element in command table
;	Null if no match
searchCommandTable:
	PUSH BX
	MOV BX, commandTableOffset
	_iterateCommandTable:
		MOV DI, [DS:BX]
		OR DI, DI
		JZ _endIterateCommandTable
		MOV SI, commandString
		MOV CX, [DS:commandStringLength]	
		REPE CMPSB
		JE _commandMatch
		ADD BX, 8
		JMP _iterateCommandTable
	_commandMatch:
		MOV AX, BX
		POP BX
		RET
	_endIterateCommandTable:
		POP BX
		XOR AX, AX
		RET

__hang:
	HLT
	JMP __hang

%include "src/macros/ascii.asm"
		
%include "src/keyboard/get-keystroke.asm"
%include "src/console/print-char.asm"
%include "src/console/print-string.asm"
%include "src/console/print-hex.asm"
%include "src/console/clear.asm"
%include "src/console/clear-row.asm"
%include "src/console/set-cursor.asm"
%include "src/console/newline.asm"
%include "src/console/backspace.asm"
%include "src/disk-io/read-sectors.asm"

DB "start data section --> |"

charmPartitionLbaLow:
	DW 0
charmPartitionLbaMid:
	DW 0
charmPartitionLbaHigh:
	DW 0
commandStringLength:
	DW 0
commandString:
	TIMES maxCommandLength DB 0
stringCommandTableError:
	DB "Error reading command table. Halting.", asciiNull
stringIOError:
	DB "IO error while reading disk. Halting.", asciiNull
stringHelp:
	DB "Commands:", asciiNewline
	DB "    gpt-info", asciiNewline
	DB "        Display info stored in GPT header", asciiNewline
	DB "    lsparts", asciiNewline
	DB "        Describe each partition on the boot disk", asciiNewline
	DB "    help", asciiNewline
	DB "        Display this screen", asciiNewline
	DB asciiNull
commandNotFoundMsg:
	DB "No such command. Type 'help' for a list of commands.", asciiNull
commandDebugMsg:
	DB "Loading program from LBA: ", asciiNull
commandClearScreen:
	DB "clear", asciiNull
commandGPTEntries:
	DB "lsparts", asciiNull
commandHelp:
	DB "help", asciiNull

DB "| <-- end binary"

TIMES 32768-($-$$) DB 0
