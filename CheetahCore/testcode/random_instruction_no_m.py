import random

# RV32I Excluding AUIPC, memory instructions, and load instructions
RV32I_ALU_INSTRUCTIONS = [
    'ADDI',    
    'SLTI',   
    'SLTIU',   
    'XORI',    
    'ORI',     
    'ANDI',    
    'SLLI',   
    'SRLI',    
    'SRAI',    
    'ADD',     
    'SUB',   
    'SLL',    
    'SLT',    
    'SLTU',    
    'XOR',     
    'SRL',     
    'SRA',    
    'OR',   
    'AND'      
]

def generate_instruction():
    inst_type = random.choice(RV32I_ALU_INSTRUCTIONS)
    rd = random.randint(1, 31)
    rs1 = random.randint(0, 31)

    if inst_type in ['ADDI', 'SLTI', 'SLTIU', 'XORI', 'ORI', 'ANDI', 'SLLI', 'SRLI', 'SRAI']:
        immediate = random.randint(0, 31)
        return f"{inst_type} x{rd}, x{rs1}, {immediate}"

    rs2 = random.randint(0, 31)
    return f"{inst_type} x{rd}, x{rs1}, x{rs2}"

def generate_instructions(num_instructions):
    return [generate_instruction() for _ in range(num_instructions)]

def write_instructions_to_file(instructions, filename):
    with open(filename, 'w') as f:
        for instruction in instructions:
            f.write(f"{instruction}\n")

def main(num_instructions=100, output_file='riscv_instructions.txt'):
    # Clear registers x5, x10, and x11 at the start
    clear_instructions = [
        'ADDI x5, x0, 0',   # Clear x5
        'ADDI x10, x0, 0',  # Clear x10
        'ADDI x11, x0, 0'   # Clear x11
    ]
    
    # Generate random instructions
    instructions = clear_instructions + generate_instructions(num_instructions)
    
    # Add the halt instruction at the end
    instructions.append('SLTI x0, x0, -256')  # Halt instruction
    
    # Write all instructions to the output file
    write_instructions_to_file(instructions, output_file)
    print(f"Generated {num_instructions} instructions and saved to {output_file}")

if __name__ == "__main__":
    num_instructions = 10000 
    output_file = 'only_alu_random.s'  
    main(num_instructions, output_file)
