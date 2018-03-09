; Set DS:SI to point to 2-bytes in memory to print
printHexWord:
	PUSH BX
	MOV BX, [DS:SI]
	MOV CX, 4   ;four places
	hexloop:
		ROL BX, 4   ;leftmost will
		MOV AX, BX   ; become
		AND AX, 0x0f   ; rightmost index into hexstr
		ADD AL, '0'
					CMP AL, '9'
					JLE noshift
					ADD AL, 7
					noshift:
					; The code above maps digits A-F properly.
		PUSH CX
		CALL printChar
		POP CX
		INT 0x10
		LOOP hexloop
	POP BX
	RET

printHexDword:
	ADD SI, 2
	CALL printHexWord
	SUB SI, 2
	CALL printHexWord
	RET

printHexQuad:
	ADD SI, 4
	CALL printHexDword
	SUB SI, 4
	CALL printHexDword
	RET

printHexOcta:
	ADD SI, 8
	CALL printHexQuad
	SUB SI, 8
	CALL printHexQuad
	RET
