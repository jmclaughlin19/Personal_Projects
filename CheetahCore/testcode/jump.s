.section .text
.globl _start
_start:

    # Initialize a value
    addi x2, x0, 0            # x5 = 0 (change this to test)

    # Check if x5 is zero
    # jal is_zero
    beq x2, x0, is_zero       # If x5 == 0, jump to is_zero
    j is_not_zero             # Jump to is_not_zero if x5 != 0

is_zero:
    # Handle zero case
    addi x2, x2, 1            # Increment x5 by 1
    j end                      # Jump to end

is_not_zero:
    # Handle non-zero case
    addi x2, x2, -1           # Decrement x5 by 1
    j end                      # Jump to end

end:
    # End of the program, magic instruction to terminate simulation
    slti x0, x0, -256         # This will end the simulation