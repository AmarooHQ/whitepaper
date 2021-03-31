#!/usr/bin/env sage

import sys
import datetime
import random as _random
from sage.all import *

def add_vertices_and_edges(graph, name, vertices_to_link_to):
    graph.add_vertex(name=name)
    graph.add_edges((v, name) for v in vertices_to_link_to)

def shuffle(xs):
    xs_copy = xs.copy()
    _random.shuffle(xs_copy)
    return xs_copy

for n_simplex_chains in [1, 2, 3, 4, 5, 7, 8, 11, 12, 17, 29]:
    tiled_simplex = graphs.EmptyGraph()
    core_simplex_vertex_names = []
    partitions = []

    for i in range(n_simplex_chains):
        n = f"C_{i}"
        add_vertices_and_edges(tiled_simplex, n, core_simplex_vertex_names)
        core_simplex_vertex_names.append(n)
    partitions.append(core_simplex_vertex_names)

    gfx = tiled_simplex.plot(
        partition=shuffle(partitions), vertex_labels=False, vertex_size=200,
        graph_border=False, figsize=18, layout="circular",
        iterations=417
        )
    gfx.save_image(f'd1-many-tiled-{n_simplex_chains}-simplexes.svg')
    print(f"{datetime.datetime.now()} -- Rendered tiled {n_simplex_chains}-simplexes at d1")

    for t in range(3):
        tile_vertex_names = []
        for i in range(n_simplex_chains):
            n = f"T_{t}_{i}"
            add_vertices_and_edges(tiled_simplex, n, core_simplex_vertex_names + tile_vertex_names)
            tile_vertex_names.append(n)
        partitions.append(tile_vertex_names)

    gfx = tiled_simplex.plot(
        partition=shuffle(partitions), vertex_labels=False, vertex_size=200,
        graph_border=False, figsize=18, layout="spring",
        iterations=417
        )
    gfx.save_image(f'd2-many-tiled-{n_simplex_chains}-simplexes.svg')
    print(f"{datetime.datetime.now()} -- Rendered tiled {n_simplex_chains}-simplexes at d2")

    d2_tiles = partitions[1:]
    for t in range(2):
        for (p_i, prev_simplex_vertices) in enumerate(d2_tiles):
            tile_vertex_names = []
            for i in range(n_simplex_chains):
                n = f"T_{p_i+1}_{t}_{i}"
                add_vertices_and_edges(tiled_simplex, n, prev_simplex_vertices + tile_vertex_names)
                tile_vertex_names.append(n)
            partitions.append(tile_vertex_names)

    gfx = tiled_simplex.plot(
        partition=shuffle(partitions), vertex_labels=False, vertex_size=200,
        graph_border=False, figsize=18, layout="spring",
        iterations=417
        )
    gfx.save_image(f'd3-many-tiled-{n_simplex_chains}-simplexes.svg')
    print(f"{datetime.datetime.now()} -- Rendered tiled {n_simplex_chains}-simplexes at d3")

    d3_tiles = partitions[4:]
    for t in range(2):
        for (p_i, prev_simplex_vertices) in enumerate(d3_tiles):
            tile_vertex_names = []
            for i in range(n_simplex_chains):
                n = f"T_{p_i+4}_{t}_{i}"
                add_vertices_and_edges(tiled_simplex, n, prev_simplex_vertices + tile_vertex_names)
                tile_vertex_names.append(n)
            partitions.append(tile_vertex_names)

    gfx = tiled_simplex.plot(
        partition=shuffle(partitions), vertex_labels=False, vertex_size=200,
        graph_border=False, figsize=18, layout="spring",
        iterations=417
        )
    gfx.save_image(f'd4-many-tiled-{n_simplex_chains}-simplexes.svg')
    print(f"{datetime.datetime.now()} -- Rendered tiled {n_simplex_chains}-simplexes at d4")
