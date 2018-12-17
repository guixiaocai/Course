#include <assert.h>
#include <elf.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define IMAGE_FILE "./image"
#define ARGS "[--extended] [--vm] <bootblock> <executable-file> ..."

#define SECTOR_SIZE 512
#define OS_SIZE_LOC 2
#define BOOT_LOADER_SIG_OFFSET 0x1fe
#define BOOT_LOADER_SIG_1 0x55
#define BOOT_LOADER_SIG_2 0xaa
#define BOOT_MEM_LOC 0x7c00
#define OS_MEM_LOC 0x1000

uint8_t ext_flag = 0;

Elf32_Phdr *read_exec_file(FILE *opfile)
{
    Elf32_Word e_phoff;
    Elf32_Phdr *s;
    fseek(opfile, 0x1c, SEEK_SET);
    e_phoff = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    fseek(opfile, e_phoff, SEEK_SET);
    s = (Elf32_Phdr *)malloc(0x20);
    s->p_type   = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_offset = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_vaddr  = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_paddr  = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_filesz = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_memsz  = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_flags  = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_align  = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    return s;
}

uint8_t count_kernel_sectors(Elf32_Phdr *Phdr)
{
    uint8_t kernel_sectors_num = (Phdr->p_memsz % SECTOR_SIZE) ? (Phdr->p_filesz / 0x200 + 1) : (Phdr->p_filesz / 0x200);
    return kernel_sectors_num;
}

void write_bootblock(FILE *image, FILE *file, Elf32_Phdr *Phdr)
{
    char c;
    int i;
    fseek(file, Phdr->p_offset, SEEK_SET);
    fseek(image, 0x0, SEEK_SET);
    for(i = 0; i < SECTOR_SIZE; i++)
    {
        if(i < Phdr->p_filesz)
        {
            c = fgetc(file);
            fputc(c, image);
        }
        else
            fputc(0x0, image);
    }
    return;
}

void write_kernel(FILE *image, FILE *knfile, Elf32_Phdr *Phdr, int kernelsz)
{
    fseek(knfile, Phdr->p_offset, SEEK_SET);
    fseek(image, 0x200, SEEK_SET);
    char c;
    int i;
    for(i = 0; i < Phdr->p_memsz; i++)
    {
        if(i < Phdr->p_filesz)
        {
            c = fgetc(knfile);
            fputc(c, image);
        }
        else
            fputc(0x0, image);
    }
    return;
}

void record_kernel_sectors(FILE *image, uint8_t kernelsz)
{
    fseek(image, BOOT_LOADER_SIG_OFFSET - 1, SEEK_SET);
    fputc(kernelsz, image);
    fputc(BOOT_LOADER_SIG_1, image);
    fputc(BOOT_LOADER_SIG_2, image);
    return;
}

void extent_opt(Elf32_Phdr *Phdr_bb, Elf32_Phdr *Phdr_k, int kernelsz)
{
    if(ext_flag)
    {
        printf("Size of kernel image: 0x%x byte\n", Phdr_k->p_filesz);
		printf("Size of kernel: 0x%x byte\n", Phdr_k->p_memsz);
        printf("Kernel image offset: 0x%x\n", Phdr_k->p_offset);
        printf("Number of kernel sectors: 0x%x\n", kernelsz);
        printf("Size of bootblock image: %d byte\n", Phdr_bb->p_filesz);
        printf("Bootblock image offset: 0x%x\n", Phdr_bb->p_offset);
    }
}

int main(int argc, char *argv[])
{
    int kernelsz;
    if(argc > 1 && strcmp(argv[1], "--extended")==0)
        ext_flag = 1;
    FILE *bbfile = fopen(argv[ext_flag + 1], "rb");
    FILE *knfile = fopen(argv[ext_flag + 2], "rb");
    FILE *image = fopen(IMAGE_FILE, "wb+");
    Elf32_Phdr *Phdr_bb = read_exec_file(bbfile);
    Elf32_Phdr *Phdr_k = read_exec_file(knfile);
    kernelsz = count_kernel_sectors(Phdr_k);
    write_bootblock(image, bbfile, Phdr_bb);
    write_kernel(image, knfile, Phdr_k, kernelsz);
    record_kernel_sectors(image, kernelsz);
    extent_opt(Phdr_bb, Phdr_k, kernelsz);
    fclose(bbfile);
    fclose(knfile);
    fclose(image);
    free(Phdr_k);
    free(Phdr_bb);
    return 0;
}
