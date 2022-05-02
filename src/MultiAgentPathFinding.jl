module MultiAgentPathFinding

## Dependencies

using DataFrames
using DataGraphs
using DataStructures
using FillArrays
using Graphs
using LinearAlgebra
using OffsetArrays
using ProgressMeter
using PythonCall
using Random
using Requires
using Statistics
using StatsBase
using SparseArrays
using UnicodePlots

## Includes

include("mapf.jl")

include("utils/eval_sol.jl")
include("utils/conflicts.jl")
include("utils/reservation.jl")
include("utils/vectorize.jl")

include("paths/dijkstra.jl")
include("paths/temporal_astar.jl")
include("paths/cooperative_astar.jl")
include("paths/independent_shortest_paths.jl")

include("exact_methods/conflict_based_search.jl")

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

include("datasets/benchmarks/read.jl")
include("datasets/benchmarks/graph.jl")
include("datasets/benchmarks/mapf.jl")

## Exports

export Path, Solution
export MAPF, nb_agents

export flowtime, max_time
export VectorPriorityQueue
export find_conflict, conflict_exists, count_conflicts
export is_feasible
export path_to_vec, solution_to_mat, solution_to_mat2

export my_dijkstra_shortest_paths
export temporal_astar
export independent_astar, independent_dijkstra, independent_topological_sort
export compute_reservation
export cooperative_astar!, cooperative_astar

export conflict_based_search

export local_search_permutations
export feasibility_search!, feasibility_search
export large_neighborhood_search, large_neighborhood_search!

export agents_embedding
export edges_embedding

export flatland_mapf

export read_map, read_scenario
export GridGraph, shortest_path_grid
export benchmark_mapf

## Conditional dependencies

function __init__()
    @require GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a" begin
        using .GLMakie
        include("flatland/plot.jl")
        export plot_flatland_graph, flatland_agent_coords
    end
    @require Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0" begin
        using .Images
        include("benchmarks/plot.jl")
        export display_map
    end
    @require JuMP = "4076af6c-e467-56ae-b986-b466b2749572" begin
        @require SCIP = "82193955-e24f-5292-bf16-6f2c5261a85f" begin
            using .JuMP, .SCIP
            include("exact_methods/linear_program.jl")
            export solve_lp
        end
    end
end

end # module
