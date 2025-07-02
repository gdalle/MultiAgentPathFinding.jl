module MultiAgentPathFinding

## Dependencies

using Colors: @colorant_str
using CSV
using DataDeps: DataDep, @datadep_str, unpack, register
using DataFrames
using DataStructures: BinaryHeap, FasterForward
using DocStringExtensions
using Graphs:
    Graphs,
    AbstractGraph,
    Edge,
    nv,
    ne,
    src,
    dst,
    vertices,
    edges,
    inneighbors,
    outneighbors,
    has_vertex,
    has_edge,
    is_directed,
    add_edge!,
    weights,
    dijkstra_shortest_paths
using Random: randperm, shuffle
using SimpleWeightedGraphs: SimpleWeightedGraph, weighttype, get_weight
using StableRNGs: StableRNG

## Includes

include("structs/mapf.jl")
include("structs/graph.jl")
include("structs/solution.jl")
include("structs/reservation.jl")
include("structs/feasibility.jl")

include("paths/independent_dijkstra.jl")
include("paths/cooperative_astar.jl")

include("benchmarks/map.jl")
include("benchmarks/scenario.jl")
include("benchmarks/solution.jl")
include("benchmarks/combine.jl")

## Exports

export MAPF
export nb_agents, select_agents
export Solution, Reservation
export VertexConflict, EdgeConflict
export sum_of_costs, path_cost, find_conflict, is_feasible
export independent_dijkstra, cooperative_astar
export list_instances
export BenchmarkScenario
export read_benchmark_map, parse_benchmark_map, passable_cell, cell_color

include("init.jl")

end # module
