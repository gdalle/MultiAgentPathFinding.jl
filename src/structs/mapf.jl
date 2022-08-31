"""
    MAPF{W,G}

Instance of a Multi-Agent PathFinding problem with custom conflict rules.

# Fields

- `g::G`
- `edge_indices::Dict{Tuple{Int,Int},Int}`
- `edge_colptr::Vector{Int}`
- `edge_rowval::Vector{Int}`
- `edge_weights_vec::Vector{W}`
- `vertex_conflicts::Vector{Vector{Int}}`
- `edge_conflicts::Dict{Tuple{Int,Int},Vector{Tuple{Int,Int}}}`
- `sources::Vector{Int}`
- `destinations::Vector{Int}`
- `departure_times::Vector{Int}`
- `arrival_times::Vector{Int}`
"""
struct MAPF{W<:Real,G<:AbstractGraph{Int}}
    # Graph-related
    g::G
    # Edges-related
    edge_indices::Dict{Tuple{Int,Int},Int}
    edge_colptr::Vector{Int}
    edge_rowval::Vector{Int}
    edge_weights_vec::Vector{W}
    # Constraints-related
    vertex_conflicts::Vector{Vector{Int}}
    edge_conflicts::Dict{Tuple{Int,Int},Vector{Tuple{Int,Int}}}
    # Agents-related
    sources::Vector{Int}
    destinations::Vector{Int}
    departure_times::Vector{Int}
    max_arrival_times::Vector{Int}

    function MAPF(
        g::G,
        edge_indices,
        edge_colptr,
        edge_rowval,
        edge_weights_vec::Vector{W},
        vertex_conflicts,
        edge_conflicts,
        sources,
        destinations,
        departure_times,
        max_arrival_times,
    ) where {W,G}
        # Check arguments
        @assert is_directed(g)
        A = length(sources)
        @assert A == length(destinations)
        @assert A == length(departure_times)
        @assert A == length(max_arrival_times)
        sorted_vertex_conflicts = [sort(group) for group in vertex_conflicts]
        sorted_edge_conflicts = Dict(
            key => sort(group) for (key, group) in pairs(edge_conflicts)
        )

        return new{W,G}(
            g,
            edge_indices,
            edge_colptr,
            edge_rowval,
            edge_weights_vec,
            sorted_vertex_conflicts,
            sorted_edge_conflicts,
            sources,
            destinations,
            departure_times,
            max_arrival_times,
        )
    end
end

function Base.show(io::IO, mapf::MAPF{W,G}) where {W,G}
    return print(
        io,
        "Multi-Agent Path Finding problem\nGraph type: $G with $W weights\nNb of agents: $(length(mapf.sources))",
    )
end

function build_edge_data(g::AbstractGraph)
    edge_indices = Dict((src(ed), dst(ed)) => e for (e, ed) in enumerate(edges(g)))

    edge_colptr = Vector{Int}(undef, nv(g) + 1)
    edge_rowval = Vector{Int}(undef, ne(g))
    e = 1
    for i in vertices(g)
        edge_colptr[i] = e
        for j in outneighbors(g, i)
            edge_rowval[e] = j
            e += 1
        end
    end
    edge_colptr[nv(g) + 1] = ne(g) + 1

    edge_weights_mat = Graphs.weights(g)
    edge_weights_vec = [edge_weights_mat[src(ed), dst(ed)] for ed in edges(g)]

    return edge_indices, edge_colptr, edge_rowval, edge_weights_vec
end

function MAPF(
    g::G,
    sources::Vector{<:Integer},
    destinations::Vector{<:Integer};
    departure_times=[1 for a in 1:length(sources)],
    max_arrival_times=[typemax(Int) for a in 1:length(sources)],
    vertex_conflicts=[[v] for v in vertices(g)],
    edge_conflicts=Dict((src(ed), dst(ed)) => [(dst(ed), src(ed))] for ed in edges(g)),
) where {G}
    edge_indices, edge_colptr, edge_rowval, edge_weights_vec = build_edge_data(g)
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
        departure_times,
        max_arrival_times,
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
