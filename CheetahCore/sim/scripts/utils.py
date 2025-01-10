def parse_spike_log( file_path = "../spike/spike.log" ):
    pcs = []
    insts = []
    
    with open( file_path, "r" ) as file:
        for line in file:
            tokens = line.split()
            pcs.append( tokens[3] )
            insts.append( tokens[4].strip( "()" ) )

    return pcs, insts