"""
    MAPF{G}

Instance of a Multi-Agent PathFinding problem with custom conflict rules.

# Fields

- `g::G`
- `edge_indices::Dict{Tuple{Int,Int},Int}`
- `edge_colptr::Vector{Int}`
- `edge_rowval::Vector{Int}`
- `edge_weights_vec::Vector{Float64}`
- `vertex_conflicts::Vector{Vector{Int}}`
- `edge_conflicts::Vector{Vector{Int}}`
- `sources::Vector{Int}`
- `destinations::Vector{Int}`
- `starting_times::Vector{Int}`
"""
struct MAPF{G<:AbstractGraph{Int}}
    # Graph-related
    g::G
    # Edges-related
    edge_indices::Dict{Tuple{Int,Int},Int}
    edge_colptr::Vector{Int}
    edge_rowval::Vector{Int}
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

    edge_colptr = Vector{Int}(undef, nv(g) + 1)
    edge_rowval = Vector{Int}(undef, ne(g))
    e = 1
    for i in vertices(g)
        edge_colptr[i] = e
        for j in outneighbors(g, i)
            @assert edge_indices[i, j] == e
            edge_rowval[e] = j
            e += 1
        end
    end
    edge_colptr[nv(g) + 1] = ne(g) + 1

    # Constraints-related
    vertex_conflicts = [sort(group) for group in vertex_conflicts]
    edge_conflicts = [sort(group) for group in edge_conflicts]

    return MAPF(
        # Graph-related
        g,
        # Edges-related
        edge_indices,
        edge_colptr,
        edge_rowval,
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

"""
    nb_agents(mapf)

Count the number of agents in `mapf`.
"""
nb_agents(mapf::MAPF) = length(mapf.sources)

"""
    build_edge_weights_matrix(mapf[, edge_weights_vec])

Turn a vector `edge_weights_vec` into a sparse weighted adjacency matrix for the graph `mapf.g`.

This function doesn't allocate because the necessary index information is already in the [`MAPF`](@ref) object.
"""
function build_weights_matrix(
    mapf::MAPF, edge_weights_vec::AbstractVector=mapf.edge_weights_vec
)
    (; g, edge_colptr, edge_rowval) = mapf
    wᵀ = SparseMatrixCSC(nv(g), nv(g), edge_colptr, edge_rowval, edge_weights_vec)
    return transpose(wᵀ)
end
