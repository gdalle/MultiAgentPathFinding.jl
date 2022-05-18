"""
    MAPF{G}

Instance of a Multi-Agent PathFinding problem.

# Fields

- `graph::G`
- `rev_graph::G`
- `edge_indices::Dict{Tuple{Int,Int},Int}`
- `rev_edge_indices::Dict{Tuple{Int,Int},Int}`
- `edge_weights::Vector{Float64}`
- `edge_weights_mat::SparseMatrixCSC{Float64,Int64}`
- `vertex_groups::Vector{Vector{Int}}`
- `edge_groups::Vector{Vector{Int}}`
- `vertex_group_memberships::Vector{Vector{Int}}`
- `edge_group_memberships::Vector{Vector{Int}}`
- `sources::Vector{Int}`
- `destinations::Vector{Int}`
- `starting_times::Vector{Int}`
- `distances_to_destinations::Dict{Int,Vector{Float64}}`
"""
struct MAPF{G<:AbstractGraph{Int}}
    # Graph-related
    graph::G
    rev_graph::G
    # Edges-related
    edge_indices::Dict{Tuple{Int,Int},Int}
    rev_edge_indices::Dict{Tuple{Int,Int},Int}
    edge_weights::Vector{Float64}
    edge_weights_mat::SparseMatrixCSC{Float64,Int64}
    # Constraints-related
    vertex_groups::Vector{Vector{Int}}
    edge_groups::Vector{Vector{Int}}
    vertex_group_memberships::Vector{Vector{Int}}
    edge_group_memberships::Vector{Vector{Int}}
    # Agents-related
    sources::Vector{Int}
    destinations::Vector{Int}
    starting_times::Vector{Int}
    distances_to_destinations::Dict{Int,Vector{Float64}}
end

function MAPF(;
    graph,
    sources,
    destinations,
    starting_times=[1 for a in 1:length(sources)],
    vertex_groups=[[v] for v in 1:nv(graph)],
    edge_groups=[Int[] for _ in 1:nv(graph)],
)
    # Graph-related
    @assert is_directed(graph)
    rev_graph = reverse(graph)

    # Edges-related
    edge_indices = Dict((src(ed), dst(ed)) => e for (e, ed) in enumerate(edges(graph)))
    rev_edge_indices = Dict((dst(ed), src(ed)) => e for (e, ed) in enumerate(edges(graph)))
    edge_weights_mat = Graphs.weights(graph)
    edge_weights = [edge_weights_mat[src(ed), dst(ed)] for ed in edges(graph)]

    # Constraints-related
    vertex_groups = [sort(group) for group in vertex_groups]
    edge_groups = [sort(group) for group in edge_groups]

    vertex_group_memberships = [Int[] for _ in 1:nv(graph)]
    for (g, group) in enumerate(vertex_groups), v in group
        push!(vertex_group_memberships[v], g)
    end
    edge_group_memberships = [Int[] for _ in 1:ne(graph)]
    for (g, group) in enumerate(edge_groups), e in group
        push!(edge_group_memberships[e], g)
    end

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
        vertex_groups,
        edge_groups,
        vertex_group_memberships,
        edge_group_memberships,
        # Agents-related
        sources,
        destinations,
        starting_times,
        distances_to_destinations,
    )
end

nb_agents(mapf::MAPF) = length(mapf.sources)
