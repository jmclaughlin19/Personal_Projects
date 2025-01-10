import utils

# File path to the spike log
log_file_path = "../spike/spike.log"

def simulate_static_not_taken( pcs, insts ):
    total_branches = 0
    branch_taken_count = 0
    branch_not_taken_count = 0
    correct_predictions = 0
    
    # Opcodes for JAL, JALR, BR
    # "111", "103",
    branch_opcodes = {"99"}
    
    for idx in range( len( insts ) - 1 ):
        # Convert the inst from hex to integer
        inst = int( insts[idx], 16 )

        # Check if the inst has a valid opcode
        if str( inst & 0x7F ) in branch_opcodes:  

            # print ( "hello ") 
            total_branches += 1

            # If the next pc value is not incremented by 4, branch taken
            if ( int( pcs[idx], 16 ) != int( pcs[idx + 1], 16 ) - 4 ):
                branch_taken_count += 1
            # Branch not taken
            else:
                branch_not_taken_count += 1

    # For static not taken predictor
    correct_predictions = branch_not_taken_count

    # print( branch_taken_count, branch_not_taken_count )
    
    accuracy = ( correct_predictions / total_branches ) * 100 if total_branches > 0 else 0
    return accuracy, total_branches

def simulate_two_bit( pcs, insts ):
    total_branches = 0
    correct_predictions = 0

    branch_opcodes = {"99"}

    # Two-bit saturating counter for branch prediction
    # 0: Strongly Not Taken, 1: Weakly Not Taken
    # 2: Weakly Taken, 3: Strongly Taken
    two_bit_state = 0

    for idx in range( len( insts ) - 1 ):
        # Convert the inst from hex to integer
        inst = int( insts[idx], 16 )

        # Check if the inst has a valid opcode
        if str( inst & 0x7F ) in branch_opcodes:
            total_branches += 1
            
            # Predict taken if state > 1
            prediction = two_bit_state > 1 
            branch_taken = int( pcs[idx], 16 ) != int( pcs[idx + 1], 16 ) - 4

            # Update accuracy
            if prediction == branch_taken:
                correct_predictions += 1
           
            # Update two-bit counter
            if branch_taken:
                two_bit_state = min( two_bit_state + 1, 3 ) 
            else:
                two_bit_state = max( two_bit_state - 1, 0 ) 

    accuracy = ( correct_predictions / total_branches ) * 100 if total_branches > 0 else 0
    return accuracy, total_branches

def simulate_perceptron( pcs, insts, hist_size = 4, threshold = 2 ):
    total_branches = 0
    correct_predictions = 0

    branch_opcodes = {"99"}

    # Initialize perceptron weights for each branch PC
    weights = {}

    for idx in range( len( insts ) - 1 ):
        # Convert the inst from hex to integer
        inst = int( insts[idx], 16 )

        # Check if the inst has a valid opcode
        if str( inst & 0x7F ) in branch_opcodes:
            total_branches += 1
            pc = pcs[idx]

            # Initialize weights for a branch PC
            if pc not in weights:
                # Maintain 8 bits of history
                weights[pc] = [0] * hist_size

            # Example feature: last 8 branch outcomes (0: not taken, 1: taken)
            history = weights[pc]
            prediction = sum( history ) >= threshold
            branch_taken = int( pcs[idx], 16 ) != int( pcs[idx + 1], 16 ) - 4

            # Update accuracy
            if prediction == branch_taken:
                correct_predictions += 1

            # Update weights using perceptron learning rule
            for i in range( len( history ) ):
                if branch_taken:
                    # Increment weights for taken branches
                    weights[pc][i] = min( weights[pc][i] + 1, 1 )  
                else:
                    # Decrement weights for not-taken branches
                    weights[pc][i] = max( weights[pc][i] - 1, -1 )  

    accuracy = ( correct_predictions / total_branches ) * 100 if total_branches > 0 else 0
    return accuracy, total_branches

def simulate_tournament_predictor( pcs, insts ):
    total_branches = 0
    correct_predictions = 0

    branch_opcodes = {"99"}

    # Two-bit saturating counter for branch prediction
    two_bit_state = 0

    # Initialize perceptron weights for each branch PC
    weights = {}
    threshold = 2  # Perceptron threshold for prediction

    # Initialize tournament selector, 0 = two-bit, 1 = perceptron
    selector_state = 0 

    for idx in range( len(insts) - 1 ):
        inst = int( insts[idx], 16 )

        if str( inst & 0x7F ) in branch_opcodes:
            total_branches += 1
            pc = pcs[idx]

            # Two-bit predictor prediction
            prediction_two_bit = two_bit_state > 1
            branch_taken = int( pcs[idx], 16 ) != int( pcs[idx + 1], 16 ) - 4

            # Perceptron prediction
            if pc not in weights:
                weights[pc] = [0] * 8 
            history = weights[pc]
            prediction_perceptron = sum( history ) >= threshold

            # Select the better predictor based on the selector state
            if selector_state == 0: 
                prediction = prediction_two_bit
            # Use perceptron prediction
            else:  
                prediction = prediction_perceptron

            # Check if prediction is correct
            if prediction == branch_taken:
                correct_predictions += 1

            # Update two-bit counter
            if branch_taken:
                two_bit_state = min( two_bit_state + 1, 3 )
            else:
                two_bit_state = max( two_bit_state - 1, 0 )

            # Update perceptron weights using learning rule
            for i in range( len( history ) ):
                if branch_taken:
                    weights[pc][i] = min( weights[pc][i] + 1, 1 ) 
                else:
                    weights[pc][i] = max( weights[pc][i] - 1, -1 )   

            # Update selector state based on which prediction was correct
            if prediction == branch_taken:
                if selector_state == 0:  
                    selector_state = min( selector_state + 1, 3 )  # Saturate up
                else: 
                    selector_state = max( selector_state - 1, 0 )  # Saturate down
            else:
                if selector_state == 0:  
                    selector_state = max( selector_state - 1, 0 )  # Saturate down
                else:  
                    selector_state = min( selector_state + 1, 3 )  # Saturate up

    accuracy = ( correct_predictions / total_branches ) * 100 if total_branches > 0 else 0
    return accuracy, total_branches

def simulate_gselect( pcs, insts, ghr_size = 4, lht_size = 16 ):
    total_branches = 0
    correct_predictions = 0

    branch_opcodes = {"99"}
    
    # Global history register (GHR), initialized with 0
    ghr = 0
    ghr_mask = ( 1 << ghr_size ) - 1  # Mask for GHR to maintain ghr_size bits

    # Local history table (LHT), stores counters for each branch indexed by PC
    lht = {}

    for idx in range( len( insts ) - 1 ):
        inst = int( insts[idx], 16 )

        # Check if the inst has a valid branch opcode
        if str( inst & 0x7F ) in branch_opcodes:
            total_branches += 1
            pc = pcs[idx]

            # If the PC is not in the LHT, initialize its local history
            if pc not in lht:
                lht[pc] = [1] * lht_size  # Initialize saturating counters to weakly taken

            # Combine PC and GHR to index the local predictor
            gselect_index = ( ghr ^ int( pc, 16 ) ) & ghr_mask
            counter = lht[pc][gselect_index]

            # Predict branch outcome based on counter value
            prediction = counter > 1  # Predict taken if counter > 1
            branch_taken = int( pcs[idx], 16 ) != int( pcs[idx + 1], 16 ) - 4

            # Update accuracy
            if prediction == branch_taken:
                correct_predictions += 1

            # Update GHR: shift left, add branch outcome
            ghr = ( ( ghr << 1 ) | branch_taken ) & ghr_mask

            # Update counter in LHT
            if branch_taken:
                lht[pc][gselect_index] = min( lht[pc][gselect_index] + 1, 3 )  # Increment counter
            else:
                lht[pc][gselect_index] = max( lht[pc][gselect_index] - 1, 0 )  # Decrement counter

    accuracy = ( correct_predictions / total_branches ) * 100 if total_branches > 0 else 0
    return accuracy, total_branches

def simulate_gselect_implemented(pcs, insts, ghr_size=8, pht_size=256):
    total_branches = 0
    correct_predictions = 0

    branch_opcodes = {"99"}

    # Global history register (GHR), initialized with 0
    ghr = 0
    ghr_mask = (1 << ghr_size) - 1  # Mask for GHR to maintain ghr_size bits

    # Pattern history table (PHT), shared globally
    pht = [0] * pht_size  

    for idx in range(len(insts) - 1):
        inst = int(insts[idx], 16)

        # Check if the inst has a valid branch opcode
        if str(inst & 0x7F) in branch_opcodes:
            total_branches += 1
            pc = int(pcs[idx], 16)

            # Combine PC and GHR to index the global predictor
            gselect_index = (ghr ^ pc) & (pht_size - 1)
            counter = pht[gselect_index]

            # Predict branch outcome based on counter value
            prediction = counter > 1  # Predict taken if counter > 1
            branch_taken = int(pcs[idx], 16) != int(pcs[idx + 1], 16) - 4

            # Update accuracy
            if prediction == branch_taken:
                correct_predictions += 1

            # Update GHR: shift left, add branch outcome
            ghr = ((ghr << 1) | branch_taken) & ghr_mask

            # Update counter in PHT
            if branch_taken:
                pht[gselect_index] = min(pht[gselect_index] + 1, 3)  # Increment counter
            else:
                pht[gselect_index] = max(pht[gselect_index] - 1, 0)  # Decrement counter

    accuracy = (correct_predictions / total_branches) * 100 if total_branches > 0 else 0
    return accuracy, total_branches


def main():
    pc_values, instructions = utils.parse_spike_log( log_file_path )
    
    # Static Not-Taken Predictor
    accuracy_static_not_taken, total_branches = simulate_static_not_taken( pc_values, instructions )
    print( f"----------------------------------" )
    print( f"Branch Predictor: Static Not-Taken" )
    print( f"Total Branches: {total_branches}" )
    print( f"Accuracy: {accuracy_static_not_taken:.2f}%" )
    print( f"----------------------------------" )

    # Two-Bit Predictor
    accuracy_two_bit, total_branches_two_bit = simulate_two_bit( pc_values, instructions )
    print( f"----------------------------------" )
    print( f"Branch Predictor: Two-Bit" )
    print( f"Total Branches: {total_branches_two_bit}" )
    print( f"Accuracy: {accuracy_two_bit:.2f}%" )
    print( f"----------------------------------" )

    hist_size = 8
    threshold = 0
    # Perceptron Predictor
    accuracy_perceptron, total_branches_perceptron = simulate_perceptron( pc_values, instructions, hist_size, threshold )
    print( f"----------------------------------" ) 
    print( f"Branch Predictor: Perceptron" )
    print( f"Total Branches: {total_branches_perceptron}" )
    print( f"Accuracy: {accuracy_perceptron:.2f}%" )
    print( f"History Size: {hist_size}" )
    print( f"History Size: {threshold}" )
    print( f"----------------------------------" )

    # Tournament Predictor
    accuracy_tournament, total_branches_tournament = simulate_tournament_predictor( pc_values, instructions )
    print( f"----------------------------------" )
    print( f"Branch Predictor: Tournament" )
    print( f"Total Branches: {total_branches_tournament}" )
    print( f"Accuracy: {accuracy_tournament:.2f}%" )
    print( f"----------------------------------" )

    # GSelect Predictor
    ghr_size = 4  # Global history register size
    lht_size = 16  # Local history table size
    accuracy_gselect, total_branches_gselect = simulate_gselect(pc_values, instructions, ghr_size, lht_size)
    print( f"----------------------------------" )
    print( f"Branch Predictor: GSelect" )
    print( f"Total Branches: {total_branches_gselect}" )
    print( f"Accuracy: {accuracy_gselect:.2f}%" )
    print( f"GHR Size: {ghr_size}, LHT Size: {lht_size}" )
    print( f"----------------------------------" )

    # GSelect Predictor
    accuracy_gselect, total_branches_gselect = simulate_gselect_implemented(pc_values, instructions, 8, 256)
    print( f"----------------------------------" )
    print( f"Branch Predictor: GSelect Implemented" )
    print( f"Total Branches: {total_branches_gselect}" )
    print( f"Accuracy: {accuracy_gselect:.2f}%" )
    print( f"GHR Size: {8}, Predictor Table Size: {256}" )
    print( f"----------------------------------" )

if __name__ == "__main__":
    main()
