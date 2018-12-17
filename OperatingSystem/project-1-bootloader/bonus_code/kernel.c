#define PORT 0xbfe48000

void __attribute__((section(".entry_function"))) _start(void)
{
	// Call PMON BIOS printstr to print message "Hello OS!"
	
	//char s[] = "Hello OS!";
	//((void(*)(void * ptr))0x8007b980)(s);
	asm volatile(
		"addi $a0, $0, 'H'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, 'e'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, 'l'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, 'l'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, 'o'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, ' '\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, 'O'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, 'S'\t\n"
	    "jal  0x8007ba00\t\n"
		"addi $a0, $0, '!'\t\n"
	    "jal  0x8007ba00\t\n"		
	);
	return;
}
