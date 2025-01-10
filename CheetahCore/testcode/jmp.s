.section .text
.globl _start
_start:

    addi x7, x0, 10

    lui x6, %hi(target)
    addi x6, x6, %lo(target)

    lui x7, %hi(target2)
    addi x7, x7, %lo(target2)

    lui x8, %hi(end)
    addi x8, x8, %lo(end)

    jalr x1, x6

    addi x6, x7, 10
    addi x7, x7, 11
    addi x7, x7, 10

target2:
    addi x2, x7, 10
    jal x21, end

target:
    addi x1, x7, 10
    jal x22, target2

end:
    slti x0, x0, -256 # this is the magic instruction to end the simulation
