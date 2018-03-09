org 0

%define gptMaxReadablePartitionTableSize 4
%define gptPartitionEntriesPerSector 4

_start:
	CALL loadPartitionTable
	CALL printPartitionTable
	RETF

loadPartitionTable:
	PUSH BX
	CALL loadGpt
	MOV AL, [DS:isGPTEntriesLoaded]
	OR AL, AL
	JNZ _done_loadPartitionTable
	;CALL loadGpt
	MOV AX, [DS:gptHeader + 0x50]
	XOR DX, DX
	MOV BX, gptPartitionEntriesPerSector
	DIV BX
	OR DX, DX
	JZ _dontAdjustSectorCount
	INC AX
	_dontAdjustSectorCount:
	CMP AX, gptMaxReadablePartitionTableSize
	JLE _dontCapSectorCount
	MOV AX, gptMaxReadablePartitionTableSize
	_dontCapSectorCount:
; if there are more than 16 partitions, this will overwrite part of the program!!
; also, this function assumes the partition table is contiguous
	MOV WORD [DS:diskAccessBlockCount], AX
	MOV WORD [DS:diskAccessOffset], partitionEntries
	MOV WORD [DS:diskAccessSegment], DS
	MOV WORD [DS:diskAccessLbaLow], 2
	MOV WORD [DS:diskAccessLbaMid], 0
	MOV WORD [DS:diskAccessLbaHi], 0
	CALL readBlock
	MOV BYTE [DS:isGPTEntriesLoaded], 1
	_done_loadPartitionTable:
	POP BX
	RET

printPartitionTable:
	PUSH SI
	
	MOV SI, stringPartitionTableInfo
	CALL printString
	
	MOV SI, stringGPTPartitionCount
	CALL printString
	
	MOV SI, gptHeader + 0x50
	CALL printHexDword
	CALL newline
	
	MOV DX, partitionEntries
	MOV CX, [DS:gptHeader + 0x50]
	MOV AX, 0
	_print_partition_info_loop:
		PUSHA
		CALL printPartitionEntry
		POPA
		ADD DX, 128
		INC AX
		CMP AX, CX
		JL _print_partition_info_loop
	POP SI
	RET

; DX points to entry
; AX is partition #
printPartitionEntry:
	PUSHA
	MOV SI, stringPartitionNumber
	CALL printString
	POPA
	
	PUSHA
	MOV [DS:bufferPartitionNumber], AX
	MOV SI, bufferPartitionNumber
	CALL printHexWord
	CALL newline
	POPA
	
	PUSHA
	MOV SI, stringPartitionType
	CALL printString
	POPA
	
	PUSHA
	MOV SI, DX
	CALL printHexOcta
	CALL newline
	POPA
	
	PUSHA
	MOV SI, stringPartitionGUID
	CALL printString
	POPA
	
	PUSHA
	MOV SI, DX
	ADD SI, 0x10
	CALL printHexOcta
	CALL newline
	POPA
	
	PUSHA
	MOV SI, stringPartitionStart
	CALL printString
	POPA
	
	PUSHA
	MOV SI, DX
	ADD SI, 0x20
	CALL printHexQuad
	CALL newline
	POPA
	
	PUSHA
	MOV SI, stringPartitionEnd
	CALL printString
	POPA
	
	PUSHA
	MOV SI, DX
	ADD SI, 0x28
	CALL printHexQuad
	CALL newline
	POPA
	
	RET

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

%include "src/macros/ascii.asm"

%include "src/console/newline.asm"
%include "src/console/print-char.asm"
%include "src/console/print-string.asm"
%include "src/console/print-hex.asm"
%include "src/disk-io/read-sectors.asm"

TIMES 65536-($-$$) DB 0
SECTION .data

stringGPTPartitionCount:
	DB "    Number of partitions: ", asciiNull
stringPartitionTableInfo:
	DB "GUID Partition Table entries:", asciiNewline, asciiNull
stringPartitionNumber:
	DB "    Partition #", asciiNull
stringPartitionType:
	DB "      Partition type: ", asciiNull
stringPartitionGUID:
	DB "      Partition GUID: ", asciiNull
stringPartitionStart:
	DB "      First LBA: ", asciiNull
stringPartitionEnd:
	DB "      Last LBA: ", asciiNull
bufferPartitionNumber:
	DB 0, 0
isGPTLoaded:
	DB 0
isGPTEntriesLoaded:
	DB 0
gptHeader:
	TIMES 512 DB 0
partitionEntries:
	TIMES 512 * gptMaxReadablePartitionTableSize DB 0

debugBuffer:
	DW 0

TIMES 65536-($-$$) DB 0
