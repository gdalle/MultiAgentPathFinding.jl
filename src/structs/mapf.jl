"""
    MAPF{G}

Instance of a Multi-Agent PathFinding problem.
"""
struct MAPF{G<:AbstractGraph{Int},VC,EC}
    # Graph-related
    graph::G
    rev_graph::G
    # Edges-related
    edge_indices::SparseMatrixCSC{Int,Int}
    rev_edge_indices::SparseMatrixCSC{Int,Int}
    edge_weights::Vector{Float64}
    edge_weights_mat::SparseMatrixCSC{Float64,Int}
    # Constraints-related
    vertex_conflict_lister::VC
    edge_conflict_lister::EC
    # Agents-related
    sources::Vector{Int}
    destinations::Vector{Int}
    starting_times::Vector{Int}
    distances_to_destinations::Dict{Int,Vector{Float64}}
end

naive_vertex_conflict_lister(mapf::MAPF, v::Integer) = (v,)
naive_edge_conflict_lister(mapf::MAPF, u::Integer, v::Integer) = ((v, u),)

function MAPF(
    graph::G,
    sources::Vector{<:Integer},
    destinations::Vector{<:Integer};
    starting_times=[1 for a in 1:length(sources)],
    vertex_conflict_lister=naive_vertex_conflict_lister,
    edge_conflict_lister=naive_edge_conflict_lister,
) where {G}
    # Graph-related
    rev_graph = reverse(graph)

    # Edges-related
    I = [src(ed) for ed in edges(graph)]
    J = [dst(ed) for ed in edges(graph)]
    V = [e for (e, ed) in enumerate(edges(graph))]
    edge_indices = sparse(I, J, V, nv(graph), nv(graph))
    rev_edge_indices = sparse(J, I, V, nv(graph), nv(graph))

    edge_weights_mat = Graphs.weights(graph)
    edge_weights = [edge_weights_mat[src(ed), dst(ed)] for ed in edges(graph)]

    # Agents-related
    distances_to_destinations = Dict{Int,Vector{Float64}}()
    for d in unique(destinations)
        shortest_path_tree_from_d = my_dijkstra(
            rev_graph, d; edge_indices=rev_edge_indices, edge_weights=edge_weights
        )
        distances_to_destinations[d] = shortest_path_tree_from_d.dists
    end

    return MAPF(
        # Graph-related
        graph,
        rev_graph,
        # Edges-related
        edge_indices,
        rev_edge_indices,
        edge_weights,
        edge_weights_mat,
        # Constraints-related
        vertex_conflict_lister,
        edge_conflict_lister,
        # Agents-related
        sources,
        destinations,
        starting_times,
        distances_to_destinations,
    )
end

nb_agents(mapf::MAPF) = length(mapf.sources)
