"""
    MAPF{W,G,VC,EC}

Instance of a Multi-Agent Path Finding problem with custom conflict rules.

# Fields

- `g::G`: underlying graph
- `departures::Vector{Int}`: agent departure vertices
- `arrivals::Vector{Int}`: agent arrival vertices
- `departure_times::Vector{Int}`: agent departure times
- `vertex_conflicts::VC`: dict-like object linking vertices to their incompatibility set
- `edge_conflicts::EC`: dict-like object linking edges to their incompatibility set
- `edge_indices::Dict{Tuple{Int,Int},Int}`: dict linking edges to their rank in `edges(g)`
- `edge_colptr::Vector{Int}`: used for construction of sparse adjacency matrix
- `edge_rowval::Vector{Int}`: used for construction of sparse adjacency matrix
- `edge_weights_vec::Vector{W}`: edge weights flattened according to their rank in `edges(g)`
"""
struct MAPF{W<:Real,G<:AbstractGraph{Int},VC,EC}
    # Graph-related
    g::G
    # Agents-related
    departures::Vector{Int}
    arrivals::Vector{Int}
    departure_times::Vector{Int}
    # Constraints-related
    vertex_conflicts::VC
    edge_conflicts::EC
    # Edges-related
    edge_indices::Dict{Tuple{Int,Int},Int}
    edge_colptr::Vector{Int}
    edge_rowval::Vector{Int}
    edge_weights_vec::Vector{W}

    function MAPF(
        g::G,
        departures,
        arrivals,
        departure_times,
        vertex_conflicts::VC,
        edge_conflicts::EC,
        edge_indices,
        edge_colptr,
        edge_rowval,
        edge_weights_vec::AbstractVector{W},
    ) where {W,G,VC,EC}
        @assert is_directed(g)
        A = length(departures)
        @assert A == length(arrivals)
        @assert A == length(departure_times)
        # TODO: add more checks
        return new{W,G,VC,EC}(
            g,
            departures,
            arrivals,
            departure_times,
            vertex_conflicts,
            edge_conflicts,
            edge_indices,
            edge_colptr,
            edge_rowval,
            edge_weights_vec,
        )
    end
end

"""
    build_edge_data(g::AbstractGraph)

Precompute edge indices dictionary and useful data for construction of sparse adjacency matrix (see [`build_weights_matrix`](@ref)).
"""
function build_edge_data(g::AbstractGraph)
    edge_indices = Dict((src(ed), dst(ed)) => e for (e, ed) in enumerate(edges(g)))
    edge_weights_mat = Graphs.weights(g)

    edge_colptr = Vector{Int}(undef, nv(g) + 1)
    edge_rowval = Vector{Int}(undef, ne(g))
    edge_weights_vec = Vector{eltype(edge_weights_mat)}(undef, ne(g))

    e = 1
    for i in vertices(g)
        edge_colptr[i] = e  # i is the column
        for j in outneighbors(g, i)
            edge_rowval[e] = j  # j is the row
            edge_weights_vec[e] = edge_weights_mat[i, j]
            e += 1
        end
    end
    edge_colptr[nv(g) + 1] = ne(g) + 1

    return edge_indices, edge_colptr, edge_rowval, edge_weights_vec
end

"""
    nb_agents(mapf)

Count the number of agents.
"""
nb_agents(mapf::MAPF) = length(mapf.departures)

function Base.show(io::IO, mapf::MAPF{W,G}) where {W,G}
    return print(
        io,
        "Multi-Agent Path Finding problem\nGraph type: $G with $W weights\nGraph size: $(nv(mapf.g)) vertices and $(ne(mapf.g)) edges\nNb of agents: $(nb_agents(mapf))",
    )
end

## Default conflicts

"""
    LazyVertexConflicts

Lazy dict-like storage for the mapping `v -> [v]`.
"""
struct LazyVertexConflicts end

Base.getindex(::LazyVertexConflicts, v::Integer) = (v,)

"""
    LazyEdgeConflicts

Lazy dict-like storage for the mapping `(u, v) -> [(u, v)]`.
"""
struct LazyEdgeConflicts end

Base.getindex(::LazyEdgeConflicts, (u, v)::Tuple{T,T}) where {T<:Integer} = ((u, v),)

"""
    LazySwappingConflicts

Lazy dict-like storage for the mapping `(u, v) -> [(v, u)]`.
"""
struct LazySwappingConflicts end

Base.getindex(::LazySwappingConflicts, (u, v)::Tuple{T,T}) where {T<:Integer} = ((v, u),)

## Default constructor

"""
    MAPF(g; departures, arrivals[, departure_times, vertex_conflicts, edge_conflicts])

User-friendly constructor for a Multi-Agent Path Finding problem.

Departure times default to 1 for every agent, vertex conflicts default to [`LazyVertexConflicts`](@ref) and edge conflicts to [`LazySwappingConflicts`](@ref).
"""
function MAPF(
    g::G;
    departures,
    arrivals,
    departure_times=fill(1, length(departures)),
    vertex_conflicts=LazyVertexConflicts(),
    edge_conflicts=LazySwappingConflicts(),
) where {G}
    edge_indices, edge_colptr, edge_rowval, edge_weights_vec = build_edge_data(g)
    return MAPF(
        g,
        departures,
        arrivals,
        departure_times,
        vertex_conflicts,
        edge_conflicts,
        edge_indices,
        edge_colptr,
        edge_rowval,
        edge_weights_vec,
    )
end

"""
    build_weights_matrix(mapf[, edge_weights_vec])

Turn a vector `edge_weights_vec` into a sparse adjacency matrix for the graph `mapf.g`.

This function doesn't allocate because the necessary index information is already available in a [`MAPF`](@ref) object.
"""
function build_weights_matrix(mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec)
    return transpose(
        SparseMatrixCSC(
            nv(mapf.g), nv(mapf.g), mapf.edge_colptr, mapf.edge_rowval, edge_weights_vec
        ),
    )
end
