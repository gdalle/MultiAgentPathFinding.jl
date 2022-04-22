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
struct MAPF{G<:AbstractGraph{Int}}
    graph::G
    rev_graph::G
    edge_indices::Dict{Tuple{Int,Int},Int}
    rev_edge_indices::Dict{Tuple{Int,Int},Int}
    edge_weights::Vector{Float64}
    edge_weights_mat::SparseMatrixCSC{Float64,Int64}
    sources::Vector{Int}
    destinations::Vector{Int}
    starting_times::Vector{Int}
    distances_to_destinations::Dict{Int,Vector{Float64}}
    conflict_groups::Vector{Vector{Int}}
    group_memberships::Vector{Vector{Int}}
end

function MAPF(;
    graph, sources, destinations, starting_times, conflict_groups=[[v] for v in 1:nv(graph)]
)
    @assert is_directed(graph)
    rev_graph = reverse(graph)

    edge_indices = Dict((src(ed), dst(ed)) => e for (e, ed) in enumerate(edges(graph)))
    rev_edge_indices = Dict((dst(ed), src(ed)) => e for (e, ed) in enumerate(edges(graph)))

    edge_weights_mat = weights(graph)
    edge_weights = [edge_weights_mat[src(ed), dst(ed)] for ed in edges(graph)]

    distances_to_destinations = Dict{Int,Vector{Float64}}()
    for d in unique(destinations)
        dijkstra_state = my_dijkstra_shortest_paths(
            rev_graph, d; edge_indices=rev_edge_indices, edge_weights=edge_weights
        )
        distances_to_destinations[d] = dijkstra_state.dists
    end

    group_memberships = [Int[] for v in vertices(graph)]
    for (g, group) in enumerate(conflict_groups)
        for v in group
            push!(group_memberships[v], g)
        end
    end

    return MAPF(
        graph,
        rev_graph,
        edge_indices,
        rev_edge_indices,
        edge_weights,
        edge_weights_mat,
        sources,
        destinations,
        starting_times,
        distances_to_destinations,
        conflict_groups,
        group_memberships,
    )
end

nb_agents(mapf::MAPF) = length(mapf.sources)
