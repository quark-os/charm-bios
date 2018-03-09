org 32768

%include "src/macros/ascii.asm"

;	[Note: pointers are 16 bit offsets in this segment]
;
;	struct Command {
;		char* string;
;		size_t lbaLow;
;		size_t lbaMid;
;		size_t lbaHigh;
;	};
;
;	sizeof(Command) = 8 bytes
;
;	The bootloader shall load this binary from disk before entering any
;	interactive console.
;
;	This binary contains an array of Command structures, and strings
;	storing the name of each command. Upon a command being entered, the
;	bootloader shall search this table for a command matching the string
;	entered. If one is found, it reads the 128KiB stored at the provided
;	LBA added to the starting LBA of the Charm partition, loads DS with
;	the segment of the latter 64KiB of the loaded binary, and performs a
;	far call to the beginning of the loaded binary.

commandGPTInfo:
	DW stringGPTInfo
	DW 128 + 0 * 256, 0, 0
	
commandListParts:
	DW stringListParts
	DW 128 + (1 * 256), 0, 0
	
tableEnd:
	DW 0, 0, 0, 0

stringGPTInfo:
	DB "gpt-info", asciiNull

stringListParts:
	DB "lsparts", asciiNull

TIMES 32768-($-$$) DB 0
