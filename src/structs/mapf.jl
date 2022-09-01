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
    max_arrival_times::Vector{Union{Nothing,Int}}

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
        max_arrival_times,
    ) where {W,G}
        # Check arguments
        @assert is_directed(g)
        A = length(departures)
        @assert A == length(arrivals)
        @assert A == length(departure_times)
        @assert A == length(max_arrival_times)
        for group in values(vertex_conflicts)
            @assert issorted(group)
        end
        for group in values(edge_conflicts)
            @assert issorted(group)
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
            max_arrival_times,
        )
    end
end

function Base.show(io::IO, mapf::MAPF{W,G}) where {W,G}
    return print(
        io,
        "Multi-Agent Path Finding problem\nGraph type: $G with $W weights\nNb of agents: $(length(mapf.departures))",
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

function MAPF(
    g::G,
    departures,
    arrivals;
    departure_times=fill(1, length(departures)),
    max_arrival_times=fill(nothing, length(arrivals)),
    vertex_conflicts=Dict(v => [v] for v in vertices(g)),
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
        departures,
        arrivals,
        departure_times,
        max_arrival_times,
    )
end

"""
    nb_agents(mapf)

Count the number of agents in `mapf`.
"""
nb_agents(mapf::MAPF) = length(mapf.departures)

"""
    build_edge_weights_matrix(mapf[, edge_weights_vec])

Turn a vector `edge_weights_vec` into a sparse weighted adjacency matrix for the graph `mapf.g`.

This function doesn't allocate because the necessary index information is already in the [`MAPF`](@ref) object.
"""
function build_weights_matrix(mapf::MAPF, edge_weights_vec=mapf.edge_weights_vec)
    (; g, edge_colptr, edge_rowval) = mapf
    wᵀ = SparseMatrixCSC(nv(g), nv(g), edge_colptr, edge_rowval, edge_weights_vec)
    return transpose(wᵀ)
end

function select_agents(mapf::MAPF, agents)
    return MAPF(
        # Graph-related
        mapf.g,
        # Edges-related
        mapf.edge_indices,
        mapf.edge_colptr,
        mapf.edge_rowval,
        mapf.edge_weights_vec,
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
        # Agents-related
        view(mapf.departures, agents),
        view(mapf.arrivals, agents),
        view(mapf.departure_times, agents),
        view(mapf.max_arrival_times, agents),
    )
end

select_agents(mapf::MAPF, nb_agents::Integer) = select_agents(mapf, 1:nb_agents)

## Add dummy vertices

function add_dummy_vertices(
    mapf::MAPF;
    appear_at_departure=true,
    disappear_at_arrival=true,
    departure_loop_weight=1.0,
    arrival_loop_weight=eps(0.0),
)
    @assert departure_loop_weight > 0
    @assert arrival_loop_weight > 0

    A = length(mapf.departures)
    V = nv(mapf.g)
    edge_weights_mat = Graphs.weights(mapf.g)

    augmented_sources = src.(edges(mapf.g))
    augmented_destinations = dst.(edges(mapf.g))
    augmented_weights = Float64[edge_weights_mat[src(ed), dst(ed)] for ed in edges(mapf.g)]

    new_departures = copy(mapf.departures)
    new_arrivals = copy(mapf.arrivals)

    if appear_at_departure
        new_departures .= (V + 1):(V + A)
        append!(augmented_sources, new_departures, new_departures)
        append!(augmented_destinations, new_departures, mapf.departures)
        append!(augmented_weights, fill(departure_loop_weight, A), fill(eps(0.0), A))
        V += A
    end

    if disappear_at_arrival
        new_arrivals .= (V + 1):(V + A)
        append!(augmented_sources, mapf.arrivals, new_arrivals)
        append!(augmented_destinations, new_arrivals, new_arrivals)
        append!(augmented_weights, fill(eps(0.0), A), fill(arrival_loop_weight, A))
    end

    augmented_g = SimpleWeightedDiGraph(
        augmented_sources, augmented_destinations, augmented_weights
    )

    new_max_arrival_times = [isnothing(t) ? nothing : t + 2 for t in mapf.max_arrival_times]

    return MAPF(
        augmented_g,
        new_departures,
        new_arrivals;
        departure_times=mapf.departure_times,
        max_arrival_times=new_max_arrival_times,
        vertex_conflicts=mapf.vertex_conflicts,
        edge_conflicts=mapf.edge_conflicts,
    )
end
