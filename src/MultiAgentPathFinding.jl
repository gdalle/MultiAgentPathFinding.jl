module MultiAgentPathFinding

## Dependencies

using ColorTypes
using DataStructures
using Graphs
using GridGraphs
using LinearAlgebra
using ProgressMeter
using Random
using Statistics
using StatsBase: StatsBase, sample
using SparseArrays

## Includes

include("structs/mapf.jl")
include("structs/path.jl")
include("structs/solution.jl")
include("structs/reservation.jl")

include("eval/conflicts.jl")
include("eval/feasibility.jl")
include("eval/cost.jl")

include("paths/dijkstra.jl")
include("paths/independent_dijkstra.jl")
include("paths/temporal_astar.jl")
include("paths/cooperative_astar.jl")

include("local_search/neighborhood.jl")
include("local_search/large_neighborhood_search.jl")
include("local_search/feasibility_search.jl")

include("learning/features_agents.jl")
include("learning/features_edges.jl")

include("benchmark/read.jl")
include("benchmark/mapf.jl")
include("benchmark/plot.jl")

## Exports

export MAPF, nb_agents
export TimedPath
export path_to_vec, path_to_vec_sparse
export Solution
export solution_to_mat
export Reservation
export compute_reservation, update_reservation!

export flowtime, max_time
export find_conflict, conflict_exists, count_conflicts
export is_feasible

export forward_dijkstra, backward_dijkstra
export temporal_astar
export independent_dijkstra, agent_dijkstra
export cooperative_astar!, cooperative_astar

export local_search_permutations
export feasibility_search!, feasibility_search
export large_neighborhood_search!, large_neighborhood_search

export agent_embedding, all_agents_embedding
export edge_embedding, all_edges_embedding

export read_benchmark_map, read_benchmark_scenario
export display_benchmark_map
export benchmark_mapf

end # module
