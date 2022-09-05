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
- `departures::Vector{Int}`
- `arrivals::Vector{Int}`
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
    vertex_conflicts::Dict{Int,Vector{Int}}
    edge_conflicts::Dict{Tuple{Int,Int},Vector{Tuple{Int,Int}}}
    # Agents-related
    departures::Vector{Int}
    arrivals::Vector{Int}
    departure_times::Vector{Int}
    stay_at_arrival::Bool

    function MAPF(
        g::G,
        edge_indices,
        edge_colptr,
        edge_rowval,
        edge_weights_vec::Vector{W},
        vertex_conflicts,
        edge_conflicts,
        departures,
        arrivals,
        departure_times,
        stay_at_arrival;
        check_sorted=true,
    ) where {W,G}
        # Check arguments
        @assert is_directed(g)
        A = length(departures)
        @assert A == length(arrivals)
        @assert A == length(departure_times)
        if check_sorted
            for group in values(vertex_conflicts)
                @assert issorted(group)
            end
            for group in values(edge_conflicts)
                @assert issorted(group)
            end
        end
        return new{W,G}(
            g,
            edge_indices,
            edge_colptr,
            edge_rowval,
            edge_weights_vec,
            vertex_conflicts,
            edge_conflicts,
            departures,
            arrivals,
            departure_times,
            stay_at_arrival,
        )
    end
end

"""
    nb_agents(mapf)

Count the number of agents in `mapf`.
"""
nb_agents(mapf::MAPF) = length(mapf.departures)

weights_type(::MAPF{W}) where {W} = W
graph_type(::MAPF{W,G}) where {W,G} = G

function Base.show(io::IO, mapf::MAPF{W,G}) where {W,G}
    return print(
        io,
        "Multi-Agent Path Finding problem\nGraph type: $G with $W weights\nGraph size: $(nv(mapf.g)) vertices and $(ne(mapf.g)) edges\nNb of agents: $(nb_agents(mapf))",
    )
end

function MAPF(
    g::G,
    departures,
    arrivals;
    departure_times=fill(1, length(departures)),
    vertex_conflicts=Dict(v => [v] for v in vertices(g)),
    edge_conflicts=Dict(
        (src(ed), dst(ed)) => [(src(ed), dst(ed)), (dst(ed), src(ed))] for ed in edges(g)
    ),
    stay_at_arrival=true,
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
        departures,
        arrivals,
        departure_times,
        stay_at_arrival,
    )
end

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
    build_edge_weights_matrix(mapf[, edge_weights_vec])

Turn a vector `edge_weights_vec` into a sparse weighted adjacency matrix for the graph `mapf.g`.

This function doesn't allocate because the necessary index information is already in the [`MAPF`](@ref) object.
"""
function build_weights_matrix(mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec)
    return transpose(
        SparseMatrixCSC(
            nv(mapf.g), nv(mapf.g), mapf.edge_colptr, mapf.edge_rowval, edge_weights_vec
        ),
    )
end
