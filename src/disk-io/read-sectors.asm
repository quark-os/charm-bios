diskAccessPacket:
	DB 0, 0x10
diskAccessBlockCount:
	DW 0
diskAccessOffset:
	DW 0
diskAccessSegment:
	DW 0
diskAccessLbaLow:
	DW 0
diskAccessLbaMid:
	DW 0
diskAccessLbaHi:
	DW 0, 0

; Disk access packet must be filled before calling this
readBlock:
	PUSH SI
	MOV SI, diskAccessPacket
	MOV AH, 0x42
	MOV DL, 0x80
	INT 0x13
	POP SI
	RET
