"""
    MultiAgentPathFinding

A package for Multi-Agent Path Finding instances and algorithms.
"""
module MultiAgentPathFinding

## Dependencies

using Colors: @colorant_str
using CPUTime: CPUtime_us
using DataDeps: DataDep, @datadep_str, unpack, register
using DataStructures: BinaryHeap
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
    weights
using MetaGraphsNext: MetaGraph
using ProgressMeter: Progress, ProgressUnknown, next!
using Random: randperm, shuffle
using SimpleWeightedGraphs: SimpleWeightedGraph
using StatsBase: sample

## Includes

include("structs/mapf.jl")
include("structs/path.jl")
include("structs/solution.jl")
include("structs/reservation.jl")
include("structs/conflict.jl")
include("structs/tree.jl")

include("paths/temporal_astar.jl")
include("paths/independent_dijkstra.jl")
include("paths/cooperative_astar.jl")

include("local_search/neighborhoods.jl")
include("local_search/optimality_search.jl")
include("local_search/feasibility_search.jl")
include("local_search/double_search.jl")

include("benchmarks/map.jl")
include("benchmarks/scenario.jl")
include("benchmarks/combine.jl")

## Exports

export MAPF, nb_agents, select_agents
export TimedPath
export path_weight, flowtime, makespan, find_conflict, is_feasible
export independent_dijkstra, temporal_astar, cooperative_astar, repeated_cooperative_astar
export feasibility_search, optimality_search, double_search

export read_benchmark_map, parse_benchmark_map, cell_color
export read_benchmark_scenario, parse_benchmark_scenario
export read_benchmark

function __init__()
    register(
        DataDep(
            "mapf-map",
            """
            All maps from the Sturtevant MAPF benchmarks (73K)
            https://movingai.com/benchmarks/mapf/index.html
            """,
            "https://movingai.com/benchmarks/mapf/mapf-map.zip";
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
            "https://movingai.com/benchmarks/mapf/mapf-scen-random.zip";
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
            "https://movingai.com/benchmarks/mapf/mapf-scen-even.zip";
            post_fetch_method=unpack,
        ),
    )
    return nothing
end

end # module
