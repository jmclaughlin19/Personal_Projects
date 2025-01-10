import random
import math
import utils

class PLRU:
    def __init__( self, num_ways ):
        self.num_ways = num_ways
        self.num_levels = int( math.log2( num_ways ) )
        self.tree = [0] * self.num_levels

    def update_tree( self, accessed_way ):
        """Update the PLRU tree based on the accessed way."""
        # Traverse the tree from the root to the leaves
        current_node = 0
        for level in range( self.num_levels ):
            if accessed_way & ( 1 << (self.num_levels - level - 1 ) ):
                # If accessed_way has a 1 in the current bit, go right
                self.tree[level] = 1
            else:
                # Otherwise, go left
                self.tree[level] = 0

    def get_lru_way( self ):
        """Determine the LRU way using the PLRU tree."""
        current_node = 0
        for level in range(self.num_levels):
            if self.tree[level] == 0:
                current_node = current_node * 2
            else:
                current_node = current_node * 2 + 1
        
        return current_node

class Cache:
    def __init__( self, num_sets, num_ways, block_size = 256, replacement_policy = "PLRU" ):
        self.num_sets = num_sets
        self.num_ways = num_ways
        self.block_size = block_size

        # Assume byte addressability
        self.num_offset_bits = int( math.log2( block_size / 8 ) )
        self.num_index_bits = int( math.log2( num_sets ) )

        self.replacement_policy = replacement_policy
        self.cache = [[{"valid": False, "dirty": False, "addr": None} for _ in range( num_ways )] for _ in range( num_sets )]
        self.hits = 0
        self.misses = 0
        self.dirty_evictions = 0

        self.plru_trees = [PLRU( num_ways ) for _ in range( num_sets )]

    def get_set_index( self, addr ):
        """Return the set index for an address"""
        # Return arr[index bits]
        return ( addr >> self.num_offset_bits ) & ( ( 1 << self.num_index_bits ) - 1 )
    
    def get_tag( self, addr ):
        """Return the tag for an address"""
        # Return the addr with the index and offset bits shifted off
        return ( addr >> ( self.num_offset_bits + self.num_index_bits ) )

    def access( self, addr, write = False ):
        """Simulate a cache access"""
        set_index = self.get_set_index( addr )
        tag = self.get_tag( addr )

        # Check if the addr is in the cache (hit or miss)
        hit, evict_index = self.check_cache( set_index, tag )

        if hit:
            self.hits += 1
            # If it's a write, mark the cache line as dirty
            if write:
                self.cache[set_index][evict_index]["dirty"] = True
        else:
            self.misses += 1
            # If it's a miss, we need to bring the addr into the cache
            self.fill_cache( set_index, tag, write )

    def check_cache( self, set_index, tag ):
        """Check if the addr is in the cache."""
        for i in range( self.num_ways ):
            if self.cache[set_index][i]["valid"] and self.cache[set_index][i]["addr"] == tag:
                return True, i
        return False, -1

    def fill_cache( self, set_index, tag, write = False ):
        """Fill the cache with the new addr"""
        evict_index = self.get_eviction_index( set_index )
        # We don't care about tracking eviction here or updating values, just replacec
        
        # Place the new addr in the cache and update plru
        self.cache[set_index][evict_index] = {"valid": True, "dirty": write, "addr": tag}
        self.plru_trees[set_index].update_tree( evict_index )

    def get_eviction_index( self, set_index ):
        """Determine which cache line to evict."""
        if self.replacement_policy == "PLRU":
            return self.plru_trees[set_index].get_lru_way()
        elif self.replacement_policy == "Random":
            return random.randint(0, self.num_ways - 1)

    def get_metrics( self ):
        """Get the performance metrics."""
        total_accesses = self.hits + self.misses
        hit_rate = self.hits / total_accesses * 100 if total_accesses > 0 else 0
        miss_rate = self.misses / total_accesses * 100 if total_accesses > 0 else 0
        return hit_rate, miss_rate, self.dirty_evictions
    

def simulate_icache( pcs, insts, num_sets, num_ways, block_size ):
    """For each line in the spike log, simulate a read to the icache"""
    cache = Cache( num_sets, num_ways, block_size )
    
    for idx in range( len( insts ) ):
        addr = int( pcs[idx], 16 )
        cache.access( addr, write = False )

    return cache.get_metrics()

def optimize_icache( pcs, insts, default_vals ):
    # Optimization mode: test multiple configurations
    best_total_diff_percent = float('-inf')
    best_config = ( 16, 4, 256 )
    best_amat = 0
    best_area = 0
    best_hit_rate = 0
    best_total_diff_percent = 0
    best_amat_diff_percent = 0
    best_area_diff_percent = 0

    # Explore different cache configurations
    block_sizes = [64, 128, 256, 512] 
    num_sets_options = [2, 4, 8, 16, 32, 64, 128, 256]  
    num_ways_options = [2, 4, 8]     

    default_hit_rate = default_vals[0]
    default_miss_rate = default_vals[1]
    # Add performance counter to calculate this more precisely
    base_miss_penalty = 5
    default_amat = ( default_hit_rate * 1 / 100 ) + ( ( default_miss_rate / 100 ) * ( base_miss_penalty * ( ( DEFAULT_BLOCK_SIZE + 1 ) / 256 ) ) )
    default_area = AREA_PER_WS * ( DEFAULT_NUM_SETS * DEFAULT_NUM_WAYS )

    with open( 'cache_metrics.txt', 'w' ) as log_file:
        log_file.write( "Configuration Results:\n" )
        log_file.write( f"Default AMAT: {default_amat}, Default Area: {default_area}\n" )

        for block_size in block_sizes:
            for num_sets in num_sets_options:
                for num_ways in num_ways_options:
                    hit_rate, miss_rate, dirty_evictions = simulate_icache( pcs, insts, num_sets, num_ways, block_size )

                    ''' 
                        We will score the caches based on AMAT and area.

                        1) AMAT = hit_rate * hit_latency + miss_rate * miss_penalty
                            hit_rate is measured by the cache and returned by simulate_icache
                            hit_latency is proportional to num_ways/num_sets
                                Respect default W/S = 4/16
                            miss_rate is measured by the cache and returned by simulate_icache
                            miss_penalty is proportional to some base miss penalty scaled by the block size
                                Respect default block size of 256

                        2) Area 
                            For the default config of 4x16, we have an area of roughly 40k. Assume this is proportional
                    '''
                    # hit_latency = num_ways / num_sets
                    # Since 256 bytes is the max we can fetch per cycle, penalize larger block sizes
                    miss_penalty = base_miss_penalty * max( ( ( block_size + 1 ) / 256), 1 )
                    # For this small cache, hit latency will be forced to 1
                    amat = ( ( hit_rate / 100 ) * 1 ) + ( ( miss_rate / 100 ) * miss_penalty )
                    area = AREA_PER_WS * ( num_sets * num_ways )

                    # For scoring, compare amat and area values to the default configuration
                    amat_diff_percent = ( ( amat - default_amat ) / default_amat ) * 100
                    area_diff_percent = ( ( area - default_area ) / default_area ) * 100

                    total_diff_percent = amat_diff_percent + area_diff_percent

                    log_file.write( f"Sets: {num_sets}, Ways: {num_ways}, Block Size: {block_size}, "
                                    f"Hit Rate: {hit_rate:.2f}%, AMAT: {amat:.2f}, Area: {area:.2f}, "
                                    f"AMAT Diff: {amat_diff_percent:.2f}%, Area Diff: {area_diff_percent:.2f}%, "
                                    f"Total Diff: {total_diff_percent:.2f}%\n" )

                    # Track the best configuration
                    if total_diff_percent < best_total_diff_percent:
                        best_amat = amat
                        best_area = area
                        best_hit_rate = hit_rate
                        best_total_diff_percent = total_diff_percent
                        best_amat_diff_percent = amat_diff_percent
                        best_area_diff_percent = area_diff_percent
                        best_config = ( num_sets, num_ways, block_size )

    # Print the best configuration and its score
    print( "------------------------------------------------------------" )
    print( "Best configuration:" )
    print( f"Number of sets: {best_config[0]}" )
    print( f"Number of ways: {best_config[1]}" )
    print( f"Block size: {best_config[2]}" )
    print( f"Hit rate: {best_hit_rate:.4f}" )  
    print( f"Best AMAT: {best_amat:.2f}" )  
    print( f"Best area: {best_area:.2f}" )  
    print( f"AMAT difference percentage: {best_amat_diff_percent:.2f}%" )
    print( f"Area difference percentage: {best_area_diff_percent:.2f}%" )
    print( "------------------------------------------------------------" )

DEFAULT_NUM_SETS = 16
DEFAULT_NUM_WAYS = 4
DEFAULT_BLOCK_SIZE = 256
AREA_PER_WS = 40000 / ( DEFAULT_NUM_SETS * DEFAULT_NUM_WAYS )

def main():
    optimize = int( input( "Enter optimize (0 or 1): " ) )
    pcs, insts = utils.parse_spike_log()

    # Default configuration, can change this for testing
    ns = 16
    nw = 4
    bs = 256

    if optimize:
        hit_rate, miss_rate, dirty_evictions = simulate_icache( pcs, insts, DEFAULT_NUM_SETS, DEFAULT_NUM_WAYS, DEFAULT_BLOCK_SIZE )
        optimize_icache( pcs, insts, ( hit_rate, miss_rate, dirty_evictions ) )
    else:
        hit_rate, miss_rate, dirty_evictions = simulate_icache( pcs, insts, ns, nw, bs )
        print( f"Hit rate: {hit_rate:.2f}%" )
        print( f"Miss rate: {miss_rate:.2f}%" )
        print( f"Dirty evictions: {dirty_evictions}" )

if __name__ == "__main__":
    main()

