#include <assert.h>
#include <elf.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_bootblock(FILE *image, FILE *bbfile, Elf32_Phdr *Phdr);
Elf32_Phdr *read_exec_file(FILE *opfile);
uint8_t count_kernel_sectors(Elf32_Phdr *Phdr);
void extent_opt(Elf32_Phdr *Phdr_bb, Elf32_Phdr *Phdr_k, int kernelsz);

Elf32_Phdr *read_exec_file(FILE *opfile)
{
    Elf32_Word e_phoff;
    Elf32_Phdr *s;
    fseek(opfile, 0x1c, SEEK_SET);
    e_phoff = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    fseek(opfile, e_phoff, SEEK_SET);

    s = (Elf32_Phdr *)malloc(0x20);
    s->p_type = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_offset = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_vaddr = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_paddr = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_filesz = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_memsz = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_flags = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    s->p_align = (fgetc(opfile)) + ((fgetc(opfile))<<8) + ((fgetc(opfile))<<16) + ((fgetc(opfile))<<24);
    return s;
}

uint8_t count_kernel_sectors(Elf32_Phdr *Phdr)
{
    uint8_t kernel_sectors_num = (Phdr->p_filesz % 0x200) ? (Phdr->p_filesz / 0x200 + 1) : (Phdr->p_filesz / 0x200);
    return kernel_sectors_num;
}

void write_bootblock(FILE *image, FILE *file, Elf32_Phdr *Phdr)
{
    char c;
    int i;
    fseek(file, Phdr->p_offset, SEEK_SET);
    fseek(image, 0x0, SEEK_SET);
    for(i = 0; i < Phdr->p_filesz; i++)
    {
        c = fgetc(file);
        fputc(c, image);
    }
    return;
}

void write_kernel(FILE *image, FILE *knfile, Elf32_Phdr *Phdr, int kernelsz)
{
    fseek(knfile, Phdr->p_offset, SEEK_SET);
    fseek(image, 0x200, SEEK_SET);
    char c;
    int i;
    for(i = 0; i < Phdr->p_filesz; i++)
    {
        c = fgetc(knfile);
        fputc(c, image);
    }
    return;
}

void record_kernel_sectors(FILE *image, uint8_t kernelsz)
{
    fseek(image, 0x1fd, SEEK_SET);
    fputc(kernelsz, image);
    return;
}

void extent_opt(Elf32_Phdr *Phdr_bb, Elf32_Phdr *Phdr_k, int kernelsz)
{
    printf("Size of kernel image: 0x%x byte\n", Phdr_k->p_filesz);
    printf("Kernel image offset: 0x%x\n", Phdr_k->p_offset);
    printf("Number of kernel sectors: 0x%x\n", kernelsz);
    printf("Size of bootblock image: %d byte\n", Phdr_bb->p_filesz);
    printf("Bootblock image offset: 0x%x\n", Phdr_bb->p_offset);
    return;
}

int main()
{
    int kernelsz;
    FILE *bbfile = fopen("bootblock", "r");
    FILE *knfile = fopen("kernel", "r");
    FILE *image = fopen("image", "w+");
    Elf32_Phdr *Phdr_bb = read_exec_file(bbfile);
    Elf32_Phdr *Phdr_k = read_exec_file(knfile);
    kernelsz = count_kernel_sectors(Phdr_k);
    write_bootblock(image, bbfile, Phdr_bb);
    write_kernel(image, knfile, Phdr_k, kernelsz);
    record_kernel_sectors(image, kernelsz);
    extent_opt(Phdr_bb, Phdr_k, kernelsz);
    free(Phdr_k);
    free(Phdr_bb);
    return 0;
}
