# ASSEMBLY-CPUID-MACOS-X64
This is an ongoing project purely dune for fun, yet I think this might be informative or useful for someone. The program is essentially a command line tool for MacOS (x64 Intel) that retrieves information using the processor's CPUID instruction. The program is done purely by using assembly language, NASM-syntax to be specific.
### Current example output
![Alt text](output_example.png?raw=true "Title")

### Licensing

MIT-license

### Usage & Compilation instructons

Compile & run using this command (make sure you have a recent version of both NASM and LD):

`nasm -fmacho64 main.asm && ld -macosx_version_min 10.7.0 -o main main.o && ./main`