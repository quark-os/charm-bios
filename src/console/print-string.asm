printString: ; before calling this function, move pointer to desired string in SI
	_loop:
		; print character
		LODSB
		OR AL, AL
		JZ _endprint ; end print when encountering null character
		CMP AL, asciiNewline
		JE _print_newline
		CALL printChar
		JMP _loop
	_print_newline:
		CALL newline
		JMP _loop
	_endprint:
	RET
