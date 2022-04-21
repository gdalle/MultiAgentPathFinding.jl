"""
    Path

Vector of tuples `(t,v)` corresponding to a timed path through a graph.
"""
const Path = Vector{Tuple{Int,Int}}  # vector of tuples (t, v)

"""
    Solution

Vector of `Path`s, one for each agent of a [`MAPF`](@ref) problem.
"""
const Solution = Vector{Path}  # one path for each agent a

"""
    Reservation

Set of tuples `(t,v)` corresponding to already-occupied vertices.
"""
const Reservation = Set{Tuple{Int,Int}}

"""
    MAPF{G,EW}
"""
struct MAPF{G<:AbstractGraph{Int},EW<:AbstractMatrix{Float64}}
    graph::G
    sources::Vector{Int}
    destinations::Vector{Int}
    starting_times::Vector{Int}
    edge_weights::EW
    distances_to_destinations::Dict{Int,Vector{Float64}}
    conflict_groups::Vector{Vector{Int}}
    group_memberships::Vector{Vector{Int}}
end

function MAPF(;
    graph,
    sources,
    destinations,
    starting_times,
    edge_weights=weights(graph),
    distances_to_destinations=compute_distances(graph, destinations, edge_weights),
    conflict_groups=[[v] for v in 1:nv(graph)],
    group_memberships=compute_group_memberships(graph, conflict_groups),
)
    return MAPF(
        graph,
        sources,
        destinations,
        starting_times,
        edge_weights,
        distances_to_destinations,
        conflict_groups,
        group_memberships,
    )
end


nb_agents(mapf::MAPF) = length(mapf.sources)

function compute_distances(graph::AbstractGraph, destinations, edge_weights)
    distances_to_destinations = Dict{Int,Vector{Float64}}()
    rev_graph = is_directed(graph) ? reverse(graph) : graph
    for d in unique(destinations)
        dijkstra_state = dijkstra_shortest_paths(rev_graph, d, edge_weights)
        distances_to_destinations[d] = dijkstra_state.dists
    end
    return distances_to_destinations
end

function compute_group_memberships(graph::AbstractGraph, conflict_groups)
    group_memberships = [Int[] for v in vertices(graph)]
    for (g, group) in enumerate(conflict_groups)
        for v in group
            push!(group_memberships[v], g)
        end
    end
    return group_memberships
end
