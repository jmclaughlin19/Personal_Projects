add_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:

    # sw x9, 20(x2)
    # sw x1, (x2)
    # sw x3, (x4)
    # sw x8, (x12)
    # sw x9, (x13)
    # lw x15, (x23)
    # sw x1, (x2)
    # sw x3, (x4)


    # sw x8, (x12)
    # sw x9, (x13)
    # lw x15, (x23)

    # addi x2, x0, 10

    # lui x6, %hi(target)
    # addi x6, x6, %lo(target)

    # lui x7, %hi(target2)
    # addi x7, x7, %lo(target2)

    # lui x8, %hi(halt)
    # addi x8, x8, %lo(halt)

    # jalr x1, x6

    addi x6, x2, 10
    addi x2, x2, 11
    addi x2, x2, 10
    addi x6, x2, 13
    addi x6, x2, 10
    addi x2, x2, 11
    addi x2, x2, 10
    addi x6, x2, 13


    addi x6, x2, 10
    addi x2, x2, 11
    addi x2, x2, 10
    # addi x6, x2, 13
    # addi x6, x2, 10
    # addi x2, x2, 11
    # addi x2, x2, 10
    # addi x6, x2, 13
    
    # target2:
    #     addi x2, x2, 10
    #     jal x23, halt

    # target:
    #     addi x1, x2, 10
    #     jal x12, target2


    # Set up a memory address for storing results
    # lui x5, 0x1eceb
    # addi x5, x5, 0x0000
    # lui x6, 0x1eceb
    # addi x6, x6, 0x000C
    # nop
    # nop
    # sh x0, 0(x6)
    # lui x7, 0x1eceb
    # addi x7, x7, 0x0008
    # lui x8, 0x1eceb
    # addi x8, x8, 0x000C
    # lw x1, 0(x5)
    # # lb: Load byte from x7
    # lb x3, 0(x7)
    # # lbu: Load unsigned byte from x7
    # lbu x11, 0(x6)
    # # # # lhu: Load unsigned halfword from x8
    # lb x12, 1(x8)
    # # # # lh: Load halfword from x5
    # lh x13, 0(x8)
    # sw x2, 0(x6)
    # # # # sb: Store byte to x8
    # sb x4, 0(x8)
    # sh: Store halfword to x6
    # sh x0, 1(x6)





























#     lui x5, 0x1eceb
  
#     addi x5, x5, 0x0000
   

#     addi x2, x2, 0x004
 

#     lui x6, 0x1eceb
   
#     addi x6, x6, 0x0004
    
 

#     lui x7, 0x1eceb
   
#     addi x7, x7, 0x0008
    

#     lui x8, 0x1eceb
  
#     addi x8, x8, 0x000c

  
#    	lw x1, 0(x5)
 
#     sw x2, 0(x6)

#     lw x3, 0(x7)

#     sw x4, 0(x8)



#     lui x5, 0x1eceb

#     addi x5, x5, 0x0000
 

#     lui x6, 0x1eceb
   
#     addi x6, x6, 0x0004
    

#     lui x7, 0x1eceb
   
#     addi x7, x7, 0x0008
    

#     lui x8, 0x1eceb
    
#     addi x8, x8, 0x000c


#     lb x1, 0(x5)
   
#     sb x2, 0(x6)
  
#     lh x3, 0(x7)

#     sh x4, 0(x8)
#     lb x1, 0(x5)
#     sb x2, 0(x6)
  
#     lh x3, 0(x7)

#     sh x4, 0(x8)

#     lui x5, 0x1eceb
    
#     addi x5, x5, 0x0000
  
#     lui x6, 0x1eceb
    
#     addi x6, x6, 0x0004
    
#     lui x7, 0x1eceb
    
#     addi x7, x7, 0x0008
   
#     lui x8, 0x1eceb
   
#     addi x8, x8, 0x000c

#     lbu x1, 0(x5)

#     sb x2, 0(x6)

#     lhu x3, 0(x7)

#     sw x4, 0(x8)

#     lui x5, 0x1eceb

# and x11, x0, x0
# and x10, x0, x0
# and x5, x0, x0
# lui x5, 0x1eceb
# addi x5, x5, 0x0000
# lui x6, 0x1eceb
# addi x6, x6, 0x0004
# lui x7, 0x1eceb
# addi x7, x7, 0x0008
# lui x8, 0x1eceb
# addi x8, x8, 0x000C
# lw x1, 0(x5)
# sw x2, 0(x6)
# # # lb: Load byte from x7
# lb x3, 0(x7)
# # sb: Store byte to x8
# sb x4, 0(x8)
# # # lh: Load halfword from x5
# lh x9, 0(x5)
# # sh: Store halfword to x6
# sh x10, 0(x6)
# # # lbu: Load unsigned byte from x7
# lbu x11, 0(x7)
# # # lhu: Load unsigned halfword from x8
# # lhu x12, 0(x8)
# # lui x2, 0xceceb
# lhu x12, 0(x8)
# # addi x6, x6, 0x0004
# # lui x7, 0xceceb
# # addi x7, x7, 0x0008
# # lui x8, 0xceceb
# # addi x8, x8, 0x000C
# # # lw x1, 0(x2)
# # sw x2, 0(x6)
# # # # # lb: Load byte from x7
# # # lb x3, 0(x7)
# # # sb: Store byte to x8
# # # sb x4, 0(x8)
# # # # lh: Load halfword from x5
# # lh x9, 0(x2)
# # # sh: Store halfword to x6
# # sh x10, 0(x6)
# # # lbu: Load unsigned byte from x7
# # lbu x11, 0(x7)
# # # lhu: Load unsigned halfword from x8
# # lhu x12, 0(x7)
# # and x2, x1, x1





# # ADDI x1, x0, 230
# # ADDI x2, x0, 408
# # ADDI x3, x0, 100
# # ADDI x4, x0, 141
# # DIVU x1, x3, x1
# # MULHU x4, x1, x3
# # SLT x2, x4, x1
# # SLTU x2, x1, x1
# # REMU x2, x2, x1
# # DIV x11, x7, x0
# # MUL x13, x20, x28
# # REMU x20, x7, x3
# # ORI x28, x13, 9
# # SRAI x7, x7, 25
# # REM x11, x3, x11
# # REMU x23, x9, x1
# # DIVU x23, x1, x9
# # MULHU x23, x30, x12
# # REM x4, x7, x0
# # MULH x9, x2, x23
# # SRL x23, x0, x11
# # MULH x7, x0, x0
# # REM x17, x0, x0
# # DIV x18, x6, x1
# # DIVU x26, x9, x19
# # REM x23, x20, x6
# # MULHSU x30, x2, x26
# # DIV x16, x16, x31
# # REMU x4, x14, x25
# # ADDI x2, x7, 4
# # MULHSU x14, x30, x0
# # SLTIU x9, x26, 0
# # DIV x12, x12, x18
# # XORI x1, x25, 18
# # REMU x21, x19, x29
# # REM x17, x11, x18
# # DIVU x1, x16, x10
# # DIV x16, x4, x29
# # XOR x30, x28, x29
# # SUB x22, x20, x1

# # and x5, x0, 0
# # and x10, x0, 0
# # and x11, x0, 0

# # addi x1, x1, 2047 
# # addi x2, x2, 1
# # # addi x2, x2, 2047

# # mul x1, x1, x1
# # mul x1, x1, x1
# # mul x1, x1, x1
# # mul x1, x1, x1
# # mul x1, x1, x1
# # mul x1, x1, x1


# # mulh x1, x1, x2


# # mulh x1, x1, x2

# # Guarantee that all registers are cleared
# # SLTU x17, x11, x20
# # MUL x25, x23, x31
# # MUL x17, x20, x12
# # SRLI x15, x15, 11
# # ORI x2, x29, 18
# # SRAI x11, x23, 9
# # ANDI x14, x13, 5
# # MULHU x16, x6, x18
# # SLLI x15, x26, 24
# # SRA x20, x15, x17
# # SLTU x23, x7, x30
# # REMU x23, x12, x1





# # SLL x25, x23, x16
# # XORI x24, x24, 4
# # REMU x24, x25, x15
# # REM x20, x15, x6





# # MULH x10, x5, x10


# # Infected zombie instructions (Jimmy gave them diseases) 
# # SRLI x4, x4, 20
# #




# SUB x19, x21, x23
# MUL x13, x13, x13
# MULHU x24, x1, x7




# OR x24, x6, x26
# MULHSU x15, x29, x19
# MULH x15, x12, x15



# MULH x28, x28, x2
# SLTI x28, x24, 11
# SLT x7, x8, x22
# MULHU x27, x26, x6
# SUB x12, x22, x30
# REMU x31, x6, x29
# MULH x22, x25, x31
# ADD x8, x2, x8
# DIVU x10, x8, x17
# ADD x28, x26, x5
# MULH x7, x4, x31
# MULHSU x12, x30, x22
# REMU x31, x2, x10

# and x1,  x0, x0
# and x2,  x0, x0
# and x3,  x0, x0
# and x4,  x0, x0
# and x5,  x0, x0
# and x6,  x0, x0




# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3

# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3

# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3

# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3

# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3

# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3

# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x3
# addi x1, x1, 2
# addi x2, x2, 6
# addi x5, x1, 1
# addi x6, x2, 8
# div x3, x2, x1 
# div x3, x3, x0

# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# div x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0 
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# mul x1, x0, x0
# and x4,  x4, x4
# and x4,  x4, x4
# and x4,  x4, x4
# and x4,  x4, x4
# and x4,  x4, x4
# and x4,  x4, x4
# and x4,  x4, x4



# mul x3, x2, x1
# mul x4, x6, x5
# and x4,  x0, x0
# and x5,  x0, x0
# and x6,  x0, x0
# and x7,  x0, x0
# and x8,  x0, x0
# and x9,  x0, x0
# and x10, x0, x0
# and x11, x0, x0
# and x12, x0, x0
# and x13, x0, x0
# and x14, x0, x0
# and x15, x0, x0
# and x16, x0, x0
# and x17, x0, x0
# and x18, x0, x0
# and x19, x0, x0
# and x20, x0, x0
# and x21, x0, x0
# and x22, x0, x0
# and x23, x0, x0
# and x24, x0, x0
# and x25, x0, x0
# and x26, x0, x0
# and x27, x0, x0
# and x28, x0, x0
# and x29, x0, x0
# and x30, x0, x0
# and x31, x0, x0


# add x2, x3, 1
# add x2, x4, 2
# add x2, x3, 3
# add x2, x5, 4
# add x2, x6, 5
# add x2, x7, 6
# add x2, x8, 7
# add x2, x3, 8

# and x1,  x0, x0
# and x2,  x0, x0
# and x3,  x0, x0
# and x4,  x0, x0
# and x5,  x0, x0
# and x6,  x0, x0
# and x7,  x0, x0
# and x8,  x0, x0
# and x9,  x0, x0
# and x10, x0, x0
# and x11, x0, x0
# and x12, x0, x0
# and x13, x0, x0
# and x14, x0, x0
# and x15, x0, x0
# and x16, x0, x0
# and x17, x0, x0
# and x18, x0, x0
# and x19, x0, x0
# and x20, x0, x0
# and x21, x0, x0
# and x22, x0, x0
# and x23, x0, x0
# and x24, x0, x0
# and x25, x0, x0
# and x26, x0, x0
# and x27, x0, x0
# and x28, x0, x0
# and x29, x0, x0
# and x30, x0, x0
# and x31, x0, x0


# # # Read after write 
# add x3, x2, x2
# add x4, x3, x3

# # # Write after read
# add x3, x2, x3
# add x2, x6, x7

# # # Write after write
# add x2, x2, x2
# add x2, x1, x2

# mul x6, x1, x1

# addi x2, x1, 2
# addi x2, x1, 2
# addi x2, x1, 2
# addi x2, x0, 2    #2 rd valdue also become dont care check after
# addi x2, x1, 2
# addi x2, x1, 2
# addi x2, x1, 2
# addi x2, x1, 2

# # ###########################################FAIL#########################################
# addi x2, x1, 2
# addi x3, x2, 4
# add x4, x2, x2
# addi x3, x2, 8
# addi x4, x1, 3
# addi x3, x1, 3
# addi x2, x3, 1
# addi x3, x2, 4
# # #############################################FAILOVER####################################

# addi x2, x3, 19

# addi x2, x0, 245
# addi x3, x1, 942
# mulhsu x4, x2, x3
# mul x4, x4, x4
# mul x4, x4, x4
# addi x1, x2, 0
# mul x4, x4, x4
# mul x4, x4, x4
# mul x4, x4, x4
# mulhsu x4, x4, x4



# addi x2, x3, 1
# addi x3, x1, 3
# addi x2, x3, 1
# addi x2, x3, 1
# addi x3, x1, 3
# addi x2, x3, 1
# addi x2, x3, 1

# add x2, x2, x2
# add x2, x2, x2
# add x2, x2, x2
# add x2, x2, x2
# add x2, x2, x2
# add x2, x2, x2
# add x2, x2, x2
# add x4, x2, x1
# add x3, x4, x2
# add x2, x2, x2
# add x2, x2, x2

# mul x1, x1, x3



# sll x12, x22, x24


halt:
    slti x0, x0, -256
