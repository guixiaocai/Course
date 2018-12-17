#define PORT 0xbfe48000

void __attribute__((section(".entry_function"))) _start(void)
{
	// Call PMON BIOS printstr to print message "Hello OS!"
	
	char s[] = "Hello OS!";
	((void(*)(void * ptr))0x8007b980)(s);

	return;
}
