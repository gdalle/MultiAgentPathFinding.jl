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

include("eval/feasibility.jl")
include("eval/cost.jl")

include("paths/tree.jl")
include("paths/dijkstra.jl")
include("paths/temporal_astar.jl")
include("paths/independent_dijkstra.jl")
include("paths/cooperative_astar.jl")

include("local_search/neighborhood.jl")
include("local_search/optimality_search.jl")
include("local_search/feasibility_search.jl")
include("local_search/double_search.jl")

## Exports

export MAPF, nb_agents, build_weights_matrix, select_agents
export TimedPath
export Solution
export Reservation
export compute_reservation, update_reservation!

export flowtime, max_time
export find_conflict
export is_feasible

export forward_dijkstra, backward_dijkstra
export independent_dijkstra
export temporal_astar
export cooperative_astar!, cooperative_astar

export feasibility_search!, feasibility_search
export optimality_search!, optimality_search
export double_search

end # module
