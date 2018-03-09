charm:
	mkdir -p bin
	nasm src/bootsector.asm -o bin/bios-bootsector.bin -O0
	nasm src/charm8086.asm -o bin/charm8086.bin -O0
	nasm src/command-table.asm -o bin/command-table.bin -O0
	nasm src/command-gpt-info.asm -o bin/command-gpt-info.bin -O0
	nasm src/command-list-parts.asm -o bin/command-list-parts.bin -O0
	nasm src/charm-partition.asm -o bin/charm-partition.bin -O0
	mksysimg -m bin/bios-bootsector.bin bin/charm-partition.bin -o charm.iso
