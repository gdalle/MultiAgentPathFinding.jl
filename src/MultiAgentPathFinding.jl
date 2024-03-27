"""
    MultiAgentPathFinding

A package for Multi-Agent Path Finding instances and algorithms.

# Exports

$(EXPORTS)
"""
module MultiAgentPathFinding

## Dependencies

using Base.Threads: @threads
using Colors: @colorant_str
using CPUTime: CPUtime_us
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
using OhMyThreads: tmap
using ProgressMeter: Progress, ProgressUnknown, next!, @showprogress
using Random: randperm, shuffle
using SimpleWeightedGraphs: SimpleWeightedGraph
using StatsBase: sample

## Includes

include("structs/mapf.jl")
include("structs/path.jl")
include("structs/solution.jl")
include("structs/reservation.jl")
include("structs/feasibility.jl")

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

export MAPF, TimedPath, Solution, Reservation, VertexConflict, EdgeConflict
export nb_agents, select_agents
export solution_cost, path_cost, find_conflict, is_feasible
export dijkstra_by_arrival, independent_dijkstra, cooperative_astar
export feasibility_search, optimality_search, double_search
export read_benchmark, list_map_names, list_scenario_names

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
