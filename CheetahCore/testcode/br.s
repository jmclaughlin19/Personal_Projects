.section .text
.globl _start
_start:

    # Initialize test registers
    addi x1, x0, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    addi x1, x1, 1000
    

beq_taken:
    addi x1, x1, -1
    mul  x2, x2, x2
    bne  x1, x0, beq_taken

    mul  x2, x2, x2
    mul  x2, x2, x2
    mul  x2, x2, x2
    mul  x2, x2, x2
    mul  x2, x2, x2
    mul  x2, x2, x2
    mul  x2, x2, x2

end:
    slti x0, x0, -256           # End simulation with magic instruction