module MultiAgentPathFinding

using DataGraphs
using DataFrames
using DataFramesMeta
using FillArrays
using GLMakie
using Graphs
using Images
using JuMP
using LinearAlgebra
using ProgressMeter
using PythonCall
using Random
using SCIP
using Statistics
using SparseArrays
using UnicodePlots
using UnPack

import StatsBase: sample

include("mapf.jl")

include("utils/eval_sol.jl")
include("utils/priority_queue.jl")
include("utils/conflicts.jl")
include("utils/vectorize.jl")

include("astar/temporal_astar.jl")
include("astar/cooperative_astar.jl")
include("astar/independent_shortest_paths.jl")

include("exact_methods/conflict_based_search.jl")
include("exact_methods/linear_program.jl")

include("local_search/large_neighborhood_search.jl")
include("local_search/feasibility_search.jl")
include("local_search/permutation_search.jl")

include("learning/features_agents.jl")
include("learning/features_edges.jl")

include("flatland/constants.jl")
include("flatland/agent.jl")
include("flatland/graph.jl")
include("flatland/utils.jl")
include("flatland/mapf.jl")
include("flatland/plot.jl")

include("benchmarks/read.jl")
include("benchmarks/graph.jl")
include("benchmarks/mapf.jl")
include("benchmarks/plot.jl")

export Path, Solution
export MAPF, nb_agents

export flowtime, max_time
export VectorPriorityQueue
export find_conflict, conflict_exists, count_conflicts
export is_feasible
export path_to_vec, solution_to_vec

export temporal_astar
export independent_astar, independent_shortest_paths
export compute_forbidden_vertices
export cooperative_astar!, cooperative_astar

export conflict_based_search
export solve_lp

export local_search_permutations, feasibility_search!
export large_neighborhood_search, large_neighborhood_search!

export agents_embedding
export edges_embedding

export flatland_mapf
export plot_flatland_graph, flatland_agent_coords

export read_map, read_scenario, display_map
export GridGraph, shortest_path_grid
export benchmark_mapf

end # module
