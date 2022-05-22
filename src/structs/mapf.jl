"""
    MAPF{G}

Instance of a Multi-Agent PathFinding problem.
"""
struct MAPF{G<:AbstractGraph{Int}}
    # Graph-related
    graph::G
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
    distances_to_destinations::Dict{Int,Vector{Float64}}
end

function MAPF(
    graph::G,
    sources::Vector{<:Integer},
    destinations::Vector{<:Integer};
    starting_times=[1 for a in 1:length(sources)],
    vertex_conflicts=[[v] for v in vertices(graph)],
    edge_conflicts=[Int[] for ed in edges(graph)],
) where {G}
    # Edges-related
    edge_indices = Dict((src(ed), dst(ed)) => e for (e, ed) in enumerate(edges(graph)))
    edge_weights_mat = Graphs.weights(graph)
    edge_weights_vec = [edge_weights_mat[src(ed), dst(ed)] for ed in edges(graph)]

    # Constraints-related
    vertex_conflicts = [sort(group) for group in vertex_conflicts]
    edge_conflicts = [sort(group) for group in edge_conflicts]

    # Agents-related
    distances_to_destinations = Dict{Int,Vector{Float64}}()
    for d in unique(destinations)
        spt_to_d = backward_dijkstra(graph, d, edge_indices, edge_weights_vec)
        distances_to_destinations[d] = spt_to_d.dists
    end

    return MAPF(
        # Graph-related
        graph,
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
        distances_to_destinations,
    )
end

nb_agents(mapf::MAPF) = length(mapf.sources)
