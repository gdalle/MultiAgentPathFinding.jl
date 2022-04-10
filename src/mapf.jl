const Path = Vector{Tuple{Int,Int}}  # vector of tuples (t, v)
const Solution = Vector{Path}  # one path for each agent a
const Reservation = Set{Tuple{Int,Int}}

Base.@kwdef struct MAPF{G<:AbstractGraph{Int},EW<:AbstractMatrix{Float64}}
    graph::G
    sources::Vector{Int}
    destinations::Vector{Int}
    starting_times::Vector{Int}
    edge_weights::EW = weights(graph)
    distances_to_destinations::Dict{Int,Vector{Float64}} = compute_distances(
        graph, destinations, edge_weights
    )
    conflict_groups::Vector{Vector{Int}} = [[v] for v in 1:nv(graph)]
    group_memberships::Vector{Vector{Int}} = compute_group_memberships(
        graph, conflict_groups
    )
end

nb_agents(mapf::MAPF) = length(mapf.sources)

function compute_distances(graph, destinations, edge_weights)
    distances_to_destinations = Dict{Int,Vector{Float64}}()
    rev_graph = is_directed(graph) ? reverse(graph) : graph
    for d in unique(destinations)
        dijkstra_state = dijkstra_shortest_paths(rev_graph, d, edge_weights)
        distances_to_destinations[d] = dijkstra_state.dists
    end
    return distances_to_destinations
end

function compute_group_memberships(graph, conflict_groups) where {V}
    group_memberships = [Int[] for v in vertices(graph)]
    for (g, group) in enumerate(conflict_groups)
        for v in group
            push!(group_memberships[v], g)
        end
    end
    return group_memberships
end
