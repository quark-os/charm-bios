charm:
	nasm src/bootsector.asm -o bin/bios-bootsector.bin -O0
	nasm src/charm8086.asm -o bin/charm8086.bin -O0
