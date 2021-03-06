module MultiAgentPathFinding

## Dependencies

using Base.Iterators
using Base.Threads

using DataStructures
using Graphs
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
include("paths/temporal_astar.jl")
include("paths/independent_dijkstra.jl")
include("paths/cooperative_astar.jl")

include("local_search/neighborhood.jl")
include("local_search/large_neighborhood_search.jl")
include("local_search/feasibility_search.jl")

include("embedding/features_agents.jl")
include("embedding/features_edges.jl")
include("embedding/features_both.jl")
include("embedding/embedding.jl")

## Exports

export MAPF, nb_agents, build_weights_matrix
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
export dijkstra_to_destinations
export independent_dijkstra, agent_dijkstra
export cooperative_astar!, cooperative_astar

export local_search_permutations
export feasibility_search!, feasibility_search
export large_neighborhood_search!, large_neighborhood_search

export mapf_embedding


end # module
