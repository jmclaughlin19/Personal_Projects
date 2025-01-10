.section .text
.globl _start
_start:

lui x5, 0x1edab
lui x6, 0x1edbb
lui x7, 0x1edcb
lui x8, 0x1eddb
lui x9, 0x1edeb


lw x1, 0(x5)
lw x2, 0(x6)
lw x3, 0(x7)
lw x4, 0(x8)
lw x12, 0(x9)

# li x2, 4
# sw x2, 0(x5)
# lb x3, 0(x7)
# lbu x11, 0(x6)
# lb x12, 1(x8)
# lh x13, 0(x8)
# sw x2, 0(x6)
# sb x4, 0(x8)
# sh x0, 1(x6)


halt:
slti x0, x0, -256 # this is the magic instruction to end the simulation