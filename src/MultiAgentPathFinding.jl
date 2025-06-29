"""
    MultiAgentPathFinding

A package for Multi-Agent Path Finding instances and algorithms.

# Exports

$(EXPORTS)
"""
module MultiAgentPathFinding

## Dependencies

using Colors: @colorant_str
using DataDeps: DataDep, @datadep_str, unpack, register
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
include("benchmarks/combine.jl")

## Exports

export MAPF
export nb_agents, select_agents
export Solution, Reservation
export VertexConflict, EdgeConflict
export sum_of_costs, path_cost, find_conflict, is_feasible
export independent_dijkstra, cooperative_astar
export list_map_names, list_scenario_names

function __init__()
    register(
        DataDep(
            "mapf-map",
            """
            All maps from the Sturtevant MAPF benchmarks (73K)
            https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-map.zip",
            "9da2e4c5ce03aa4e063b3a283ce874590b36cc4f31a297fe7ecb00d105abf288";
            post_fetch_method=unpack,
        ),
    )
    register(
        DataDep(
            "mapf-scen-random",
            """
            All random scenarios from the Sturtevant MAPF benchmarks (7.9M)
            https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-scen-random.zip",
            "20b7838f7a51f13e90a63ee138e9435fb4e41b0381becbc7313b7d3a7d859276";
            post_fetch_method=unpack,
        ),
    )
    register(
        DataDep(
            "mapf-scen-even",
            """
            All even scenarios from the Sturtevant MAPF benchmarks (9.9M)
            https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-scen-even.zip",
            "249896aaf15ef2d9beb378f954f0b7ca17189c6dec1b76a78965bbdbe714ad75";
            post_fetch_method=unpack,
        ),
    )
    return nothing
end

end # module
