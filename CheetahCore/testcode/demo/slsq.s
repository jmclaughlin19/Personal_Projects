.section .text
.globl _start
_start:

    # set up load and stores
    lui x21, 0x1edeb
    addi x21, x21, 0x0000
    lui x6, 0x1edeb
    addi x6, x6, 0x000C
    lui x7, 0x1edeb
    addi x7, x7, 0x0008
    lui x8, 0x1fdeb
    addi x8, x8, 0x000C

    # loads issued out of order inbetween stores
    mul x2, x2, x2      #result is zero but takes cycles
    add x2, x6, x2      #result is what is at 6 already
    lw x3, 0(x2)        # waiting on multiply and add
    lw x4, 0(x8)        # can go right away
    sw x4, 0(x8)        

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    # loads can be issued out of order with stores to a diffrent address
    mul x2, x2, x2
    sw  x2, 0(x8)
    lw  x4, 0(x6)  #will go before the store

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    # non commited store fowarding to loads
    addi x2, x2, 4
    sw   x2, 0(x8)
    lw   x4, 0(x8)
    lw   x19, 0(x8)
    lw   x20, 0(x8)
    lw   x22, 0(x8)


    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop


    # non commited store fowarding to loads (misaligned)
    addi x2, x2, 4
    sw   x2, 0(x8)
    lb   x4, 0(x8)
    lh   x19, 0(x8)
    lw   x20, 0(x8)
    
halt:
    slti x0, x0, -256 # this is the magic instruction to end the simulation
