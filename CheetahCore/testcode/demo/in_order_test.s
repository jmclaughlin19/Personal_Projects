.section .text
.globl _start
_start:

ADDI x1, x0, 3
ADDI x2, x0, 0
ADDI x3, x0, 0


#alu reservation station going in order
div x1, x1, x1
add x2, x0, x0
add x2, x1, x1
add x3, x1, x1
add x4, x1, x0
add x5, x1, x1
div x2, x2, x2

#mul reservation station going in order
div x1, x1, x1
mul x0, x0, x0
mul x3, x1, x1
mul x2, x1, x1

#ld reservation station going in order
lui x21, 0x1edeb
addi x21, x21, 0x0000
lui x6, 0x1edeb
lw x2, 0(x6)
addi x6, x6, 0x000C
lui x7, 0x1edeb
addi x7, x7, 0x0008
lui x8, 0x1fdeb
addi x8, x8, 0x000C

# loads issued out of order inbetween stores 
lui x1, 0x1
div x1, x1, x1
mul x21, x21, x1
lw x2, 0(x6)
lw x2, 0(x21)
lw x2, 0(x21)


halt:
slti x0, x0, -256 # this is the magic instruction to end the simulationL