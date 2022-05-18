module MultiAgentPathFinding

## Dependencies

using ColorTypes
using DataFrames
using DataFramesMeta
using DataStructures
using FastPriorityQueues
using Graphs
using GridGraphs
using LinearAlgebra
using MetaDataGraphs
using ProgressMeter
using PythonCall
using Random
using Requires
using Statistics
using StatsBase: sample
using SparseArrays
using UnicodePlots

## Includes

include("structs/mapf.jl")
include("structs/path.jl")
include("structs/reservation.jl")

include("eval/conflicts.jl")
include("eval/feasibility.jl")
include("eval/cost.jl")

include("paths/dijkstra.jl")
include("paths/independent_dijkstra.jl")
include("paths/temporal_astar.jl")
include("paths/independent_astar.jl")
include("paths/cooperative_astar.jl")

include("local_search/neighborhood.jl")
include("local_search/large_neighborhood_search.jl")
include("local_search/feasibility_search.jl")
include("local_search/permutation_search.jl")

include("learning/features_agents.jl")
include("learning/features_edges.jl")

include("datasets/flatland/constants.jl")
include("datasets/flatland/agent.jl")
include("datasets/flatland/graph.jl")
include("datasets/flatland/utils.jl")
include("datasets/flatland/mapf.jl")

include("datasets/benchmark/read.jl")
include("datasets/benchmark/mapf.jl")

## Exports

export Path, Solution
export MAPF, nb_agents

export flowtime, max_time
export VectorPriorityQueue
export find_conflict, conflict_exists, count_conflicts
export is_feasible
export path_to_vec, solution_to_mat, solution_to_mat2

export my_dijkstra
export temporal_astar
export independent_astar, independent_dijkstra, independent_topological_sort
export compute_reservation
export cooperative_astar!, cooperative_astar

export local_search_permutations
export feasibility_search!, feasibility_search
export large_neighborhood_search, large_neighborhood_search!

export agents_embedding
export edges_embedding

export flatland_mapf

export read_benchmark_map, read_benchmark_scenario
export display_benchmark_map
export benchmark_mapf

## Conditional dependencies

function __init__()
    @require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin
        using .GLMakie
        include("datasets/flatland/plot.jl")
        include("datasets/benchmark/plot.jl")
        export plot_flatland_graph, flatland_agent_coords
        export display_map
    end
end

end # module
