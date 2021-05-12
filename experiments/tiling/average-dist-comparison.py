import numpy.random as r
import numpy as np
from typing import Dict, Set, List
from collections import namedtuple
import matplotlib.pyplot as plt


"""
generate a comparison histogram of the average distances between tiles given different tiling methods.

hypothesis: tree-tiling is more efficient than tesselating tilings.
for a tesselating tiling, I devised a simple square based tiling that has v=4

output graphs seem to agree with hypothesis. for the square tiling at least

NB: if you're running this to test stuff, change n_trials to 10**5 or less so
that this script runs in <2s. With n_trials=10**7 it takes 15-20 min to run on
my machine. -MK
"""


rng = r.default_rng()
n_trials = 10**7
# valence of tree -- change this to produce graphs with different
valence = 3
# this breakpoint is nice b/c v={3,4} tree tilings
# have n_tiles very close to some depth of square tiles -- so those comparisons are good
stop_after_nodes_gt = 400

"""
for a tree of some max height, we can generate a random node via the path to get there.

a path of length l is easy: [1,0,0,1] (nb: first option can be 0,1,2 -- but other options must be 0,1)

but but not all nodes are at height h.
p(outer layer) = (3*2**(h-1)) / (3*2**h - 2)
"""


def find_tree_depth_for_valence(v=valence):
    vm1 = v - 1
    vm2 = v - 2

    total_nodes = v + 1
    nodes_added_last = v
    depth_tmp = 1
    while total_nodes < stop_after_nodes_gt:
        add_nodes = nodes_added_last * (v - 1)
        total_nodes += add_nodes
        nodes_added_last = add_nodes
        depth_tmp += 1
        print(f"T:{total_nodes}, A:{add_nodes}, D:{depth_tmp}")
    return depth_tmp


max_tree_depth = find_tree_depth_for_valence()
print(f"Tree depth: {max_tree_depth}")


def gen_random_tree_path_length(h, v=valence):
    # nodes in outer layer / total nodes
    # example with v=3 hardcoded: p = (3*2**(h-1)) / (3*2**h - 2)
    p = (v * (v-1) ** (h-1)) / (v * ((v-1) ** h - 1)/(v-2) + 1)
    # if we are in the outer layer, return this depth
    if rng.random() < p:
        return h
    # otherwise test 1 layer down
    return gen_random_tree_path_length(h - 1)


def gen_tree_path_of_len(l, v=valence):
    '''generate a random tree path of a given length'''
    if l == 0: return []
    p = np.zeros(l)
    # first choice has v options
    p[0] = rng.choice(list(range(v)))
    # other choices have v-1 options
    for i in range(1, l):
        p[i] = rng.choice(list(range(v-1)))
    return p


def gen_random_tree_path(max_dist=max_tree_depth):
    l = gen_random_tree_path_length(max_dist)
    p = gen_tree_path_of_len(l)
    return p


def tree_path_dist(p_a, p_b, offset=0):
    """
    if there are no common bits, then it's the sum of lengths.
    if there are common prefixes, then we trim those and sum the lengths after.
    """
    if len(p_a) == offset or len(p_b) == offset:
        return len(p_a) + len(p_b) - offset*2
    if p_a[offset] == p_b[offset]:
        return tree_path_dist(p_a, p_b, offset+1)
    return len(p_a) + len(p_b) - offset*2


def test_tree_path_dist():
    path_pairs = [
        [[], [], 0],
        [[], [2], 1],
        [[1], [1], 0],
        [[1], [2], 2],
        [[1], [2,1,1,1], 5],
        [[1,1,1,1], [2,1,1,1], 8],
    ]
    for a,b,e in path_pairs:
        assert tree_path_dist(a, b) == e

test_tree_path_dist()


def get_rand_tree_dist():
    return tree_path_dist(gen_random_tree_path(), gen_random_tree_path())


print(gen_random_tree_path())
print(gen_random_tree_path())
print(gen_random_tree_path())
print(gen_random_tree_path())
print(gen_random_tree_path())
print(gen_random_tree_path())


tree_dists = list(get_rand_tree_dist() for _ in range(n_trials))


"""
grid -- build out diamonds on square grid (per iteration).

new tiles marked with 'x'. existing tiles with 'o', except the origin which is '.'

0. (+1 tile)
    x

1. (+4 tiles)
    x
   x.x
    x

2. (+8 tiles)
    x
   xox
  xo.ox
   xox
    x

3. (+12 tiles)
    x
   xox
  xooox
 xoo.oox
  xooox
   xox
    x

for a given iteration, i, valid coords are within: x+y <= i

on y=0 there are 2i+1 tiles
on y=1 there are 2(i-1)+1 tiles
on y=2 there are 2(i-2)+1 tiles
on a given line there is 2(i-y)+1 tiles
"""


n_sq_nodes = 5
prev_sq_cs = 4
max_sq_dist = 1  # lag behind by 1
while n_sq_nodes < total_nodes:
    new_sq_children = 4 * (max_sq_dist + 1)
    n_sq_nodes += new_sq_children
    max_sq_dist += 1
print(f"N Square Tiles: {n_sq_nodes}; D: {max_sq_dist}")
max_sq_dist -= 1


Point = namedtuple('Point', ['x', 'y'])


def gen_coords(max_dist=max_sq_dist):
    coords = set()
    for x in range(max_dist + 1):
        for y in range(max_dist - x + 1):
            coords.add(Point(x, y))
            coords.add(Point(-x, -y))
            coords.add(Point(-x, y))
            coords.add(Point(x, -y))
    return np.array(list(coords))


tile_positions = gen_coords()

def get_rand_dist():
    a = rng.choice(tile_positions)
    b = rng.choice(tile_positions)

    return abs(a[0]-b[0]) + abs(a[1]-b[1])

sq_dists = list(get_rand_dist() for _ in range(n_trials))


tree_tiles = int(valence * (vm1**(max_tree_depth)/vm2) + 1)
square_tiles = len(tile_positions)

bins = list(range(max(max_sq_dist, max_tree_depth)*2+1))

for name, dists, buckets, n_tiles, side in [
    (f'tree (v={valence})', tree_dists, max_tree_depth*2, tree_tiles, 'left'),
    (f'square (v=4)', sq_dists, max_sq_dist*2, square_tiles, 'mid'),
    ]:
    print('Results for', name.capitalize())
    h, bin_edges = np.histogram(dists, bins=bins, density=True)
    avg = sum(dists)/len(dists)
    assert len(dists) == n_trials
    print('Average:', avg)
    print('###########################')
    print(bin_edges, bins, h, dists[:20])
    # line, = plt.plot(list(range(bins)), h)
    plt.hist(dists, bins=bins, density=True, label=f"{name}\n{n_tiles} tiles\navg dist: {avg:0.2f}", rwidth=0.5, align=side)
plt.legend()
plt.title(f'Distance between tiles for random samplings (n={n_trials})')
plt.xlabel('distance')
plt.ylabel('frequency')
plt.savefig(f"avg-dist-tmp.pdf", dpi=300)
print("Generated avg-dist-tmp.pdf. Copy this to another file if you want to keep it.")
