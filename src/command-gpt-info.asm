org 0

%define gptMaxReadablePartitionTableSize 4

; code section

_start:
	CALL loadGpt
	CALL printGPTInfo
	RETF

loadGpt:
	MOV AX, [DS:isGPTLoaded]
	JNZ _done_loadGPT
	MOV WORD [DS:diskAccessBlockCount], 1
	MOV WORD [DS:diskAccessOffset], gptHeader
	MOV WORD [DS:diskAccessSegment], DS
	MOV WORD [DS:diskAccessLbaLow], 1
	MOV WORD [DS:diskAccessLbaMid], 0
	MOV WORD [DS:diskAccessLbaHi], 0
	CALL readBlock
	MOV WORD [DS:isGPTLoaded], 1
	_done_loadGPT:
	RET

printGPTInfo:
	PUSH SI
	
	MOV SI, stringGPTInfo
	CALL printString
	CALL newline
	
	MOV SI, stringGPTGUID
	CALL printString
	
	MOV SI, gptHeader + 0x38
	CALL printHexOcta
	CALL newline
	
	MOV SI, stringGPTPartitionCount
	CALL printString
	
	MOV SI, gptHeader + 0x50
	CALL printHexDword
	CALL newline
	
	MOV SI, stringGPTFirstLBA
	CALL printString
	
	MOV SI, gptHeader + 0x28
	CALL printHexQuad
	CALL newline
	
	MOV SI, stringGPTLastLBA
	CALL printString
	
	MOV SI, gptHeader + 0x30
	CALL printHexQuad
	
	POP SI
	RET

%include "src/macros/ascii.asm"
%include "src/disk-io/read-sectors.asm"
%include "src/console/print-char.asm"
%include "src/console/newline.asm"
%include "src/console/print-string.asm"
%include "src/console/print-hex.asm"

TIMES 65536-($-$$) DB 0
SECTION .data
; data section
stringGPTInfo:
	DB "GUID Partition Table header:", asciiNull
stringGPTGUID:
	DB "    Disk GUID: ", asciiNull
stringGPTPartitionCount:
	DB "    Number of partitions: ", asciiNull
stringGPTFirstLBA:
	DB "    First usable LBA: ", asciiNull
stringGPTLastLBA:
	DB "    Last usable LBA: ", asciiNull
isGPTLoaded:
	DW 0
gptHeader:
	TIMES 512 DB 0
partitionEntries:
	TIMES 512 * gptMaxReadablePartitionTableSize DB 0
	
TIMES 65536-($-$$) DB 0
