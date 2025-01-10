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

# M Extension
RV32I_M_INSTRUCTIONS = [
    'MUL',     
    'MULH',    
    'MULHSU',  
    'MULHU',   
    'DIV',    
    'DIVU',   
    'REM',   
    'REMU'    
]

def generate_instruction(mode):
    rd = random.randint(1, 31)
    rs1 = random.randint(0, 31)

    if mode == 'alu':
        inst_type = random.choice(RV32I_ALU_INSTRUCTIONS)

        if inst_type in ['ADDI', 'SLTI', 'SLTIU', 'XORI', 'ORI', 'ANDI', 'SLLI', 'SRLI', 'SRAI']:
            immediate = random.randint(0, 31)
            return f"{inst_type} x{rd}, x{rs1}, {immediate}"

        rs2 = random.randint(0, 31)
        return f"{inst_type} x{rd}, x{rs1}, x{rs2}"

    elif mode == 'multiply':
        inst_type = random.choice([i for i in RV32I_M_INSTRUCTIONS if i.startswith('MUL')])
        rs2 = random.randint(0, 31)
        return f"{inst_type} x{rd}, x{rs1}, x{rs2}"

    elif mode == 'divide':
        inst_type = random.choice([i for i in RV32I_M_INSTRUCTIONS if i.startswith('DIV')])
        rs2 = random.randint(0, 31)
        return f"{inst_type} x{rd}, x{rs1}, x{rs2}"

    elif mode == 'remainder':
        inst_type = random.choice([i for i in RV32I_M_INSTRUCTIONS if i.startswith('REM')])
        rs2 = random.randint(0, 31)
        return f"{inst_type} x{rd}, x{rs1}, x{rs2}"

def generate_instructions(num_instructions, modes):
    instructions = []
    for _ in range(num_instructions):
        mode = random.choice(modes)  # Randomly select a mode from the provided list
        instructions.append(generate_instruction(mode))
    return instructions

def write_instructions_to_file(instructions, filename):
    with open(filename, 'w') as f:
        for instruction in instructions:
            f.write(f"{instruction}\n")

def initialize_registers():
    # Initialize registers x1 to x31 to random values between 50 and 500
    init_instructions = [f'ADDI x{i}, x0, {random.randint(50, 500)}' for i in range(1, 32)]
    return init_instructions

def main(num_instructions=100, output_file='riscv_instructions.txt', modes=['alu']):
    # Clear registers x5, x10, and x11 at the start
    clear_instructions = [
        'ADDI x5, x0, 0',   # Clear x5
        'ADDI x10, x0, 0',  # Clear x10
        'ADDI x11, x0, 0'   # Clear x11
    ]
    
    # Initialize registers
    init_instructions = initialize_registers()
    
    instructions = clear_instructions + init_instructions + generate_instructions(num_instructions, modes)
    
    instructions.append('SLTI x0, x0, -256')  # Halt instruction
    
    write_instructions_to_file(instructions, output_file)
    print(f"Generated {num_instructions} instructions ({', '.join(modes)}) and saved to {output_file}")

if __name__ == "__main__":
    num_instructions = 50000 
    output_file = 'specific_random.s'  
    modes = ['alu', 'remainder', 'divide', 'multiply']  # alu, multiply, divide, remainder
    main(num_instructions, output_file, modes)
