#!/usr/bin/env sage

# deprecated, use simplex-many-tiles.sage instead

import sys
import datetime
from sage.all import *

for n_simplex_chains in [1, 2, 3, 4, 5, 7, 8, 11, 12, 17, 29, 37, 47, 61]:
    tiled_simplex = graphs.EmptyGraph()
    core_simplex_vertex_names = []
    partitions = []

    for i in range(n_simplex_chains):
        n = f"C_{i}"
        tiled_simplex.add_vertex(name=n)
        tiled_simplex.add_edges((v, n) for v in core_simplex_vertex_names)
        core_simplex_vertex_names.append(n)
    partitions.append(core_simplex_vertex_names)

    for t in range(3):
        tile_vertex_names = []
        for i in range(n_simplex_chains):
            n = f"T_{t}_{i}"
            tiled_simplex.add_vertex(name=n)
            tiled_simplex.add_edges((v, n) for v in core_simplex_vertex_names)
            tiled_simplex.add_edges((v, n) for v in tile_vertex_names)
            tile_vertex_names.append(n)
        partitions.append(tile_vertex_names)

    gfx = tiled_simplex.plot(
        partition=partitions, vertex_labels=False, vertex_size=300,
        graph_border=False, figsize=14, layout="spring",
        iterations=500
        )
    gfx.save_image(f'tiled-{n_simplex_chains}-simplexes.png')
    print(f"{datetime.datetime.now()} -- Rendered tiled {n_simplex_chains}-simplexes")
