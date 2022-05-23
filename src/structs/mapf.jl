"""
    MAPF{G}

Instance of a Multi-Agent PathFinding problem.
"""
struct MAPF{G<:AbstractGraph{Int}}
    # Graph-related
    g::G
    # Edges-related
    edge_indices::Dict{Tuple{Int,Int},Int}
    edge_weights_vec::Vector{Float64}
    # Constraints-related
    vertex_conflicts::Vector{Vector{Int}}
    edge_conflicts::Vector{Vector{Int}}
    # Agents-related
    sources::Vector{Int}
    destinations::Vector{Int}
    starting_times::Vector{Int}
end

function MAPF(
    g::G,
    sources::Vector{<:Integer},
    destinations::Vector{<:Integer};
    starting_times=[1 for a in 1:length(sources)],
    vertex_conflicts=[[v] for v in vertices(g)],
    edge_conflicts=[Int[] for ed in edges(g)],
) where {G}
    # Edges-related
    edge_indices = Dict((src(ed), dst(ed)) => e for (e, ed) in enumerate(edges(g)))
    edge_weights_mat = Graphs.weights(g)
    edge_weights_vec = [edge_weights_mat[src(ed), dst(ed)] for ed in edges(g)]
    # Constraints-related
    vertex_conflicts = [sort(group) for group in vertex_conflicts]
    edge_conflicts = [sort(group) for group in edge_conflicts]

    return MAPF(
        # Graph-related
        g,
        # Edges-related
        edge_indices,
        edge_weights_vec,
        # Constraints-related
        vertex_conflicts,
        edge_conflicts,
        # Agents-related
        sources,
        destinations,
        starting_times,
    )
end

nb_agents(mapf::MAPF) = length(mapf.sources)

function compute_distances_to_destinations(
    mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    (; g, edge_indices, destinations) = mapf
    distances_to_destinations = Dict{Int,Vector{Float64}}()
    for d in unique(destinations)
        spt_to_d = backward_dijkstra(g, d, edge_indices, edge_weights_vec)
        distances_to_destinations[d] = spt_to_d.dists
    end
    return distances_to_destinations
end
