"""
    MultiAgentPathFinding

A package for Multi-Agent Path Finding instances and algorithms.
"""
module MultiAgentPathFinding

## Dependencies

using CPUTime: CPUtime_us
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
    weights
using ProgressMeter: Progress, ProgressUnknown, next!
using Random: randperm, shuffle
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

## Exports

export MAPF, nb_agents, select_agents
export TimedPath

export path_weight, flowtime, makespan
export find_conflict
export is_feasible

export independent_dijkstra
export temporal_astar
export cooperative_astar
export repeated_cooperative_astar

export feasibility_search
export optimality_search
export double_search

end # module
