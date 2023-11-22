"""
$(TYPEDEF)

Instance of a Multi-Agent Path Finding problem with custom conflict rules.

Agents appear at their departure vertex when the departure time comes, and they disappear as soon as they have reached the arrival vertex.

# Fields

$(TYPEDFIELDS)
"""
struct MAPF{W<:Real,G<:AbstractGraph{Int},M<:AbstractMatrix{W},VC,EC}
    # Graph-related
    "underlying graph"
    g::G
    "matrix of edge weights"
    edge_weights::M
    # Agents-related
    "agent departure vertices"
    departures::Vector{Int}
    "agent arrival vertices"
    arrivals::Vector{Int}
    "agent departure times"
    departure_times::Vector{Int}
    # Constraints-related
    "dict-like object linking vertices to their incompatibility set"
    vertex_conflicts::VC
    "dict-like object linking edges (as tuples) to their incompatibility set"
    edge_conflicts::EC

    function MAPF(
        g::G,
        edge_weights::M,
        departures,
        arrivals,
        departure_times,
        vertex_conflicts::VC,
        edge_conflicts::EC,
    ) where {G,M,VC,EC}
        A = length(departures)
        @assert A == length(arrivals)
        @assert A == length(departure_times)
        # TODO: add more checks
        return new{eltype(M),G,M,VC,EC}(
            g,
            edge_weights,
            departures,
            arrivals,
            departure_times,
            vertex_conflicts,
            edge_conflicts,
        )
    end
end

"""
    nb_agents(mapf)

Count the number of agents.
"""
nb_agents(mapf::MAPF) = length(mapf.departures)

function Base.show(io::IO, mapf::MAPF{W,G}) where {W,G}
    return print(
        io,
        """Multi-Agent Path Finding problem
        Graph type: $G with $W weights
        Graph size: $(nv(mapf.g)) vertices and $(ne(mapf.g)) edges
        Nb of agents: $(nb_agents(mapf))""",
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
    MAPF(
        g[, edge_weights];
        departures, arrivals[, departure_times, vertex_conflicts, edge_conflicts]
    )

User-friendly constructor for a Multi-Agent Path Finding problem.

Departure times default to 1 for every agent, vertex conflicts default to [`LazyVertexConflicts`](@ref) and edge conflicts to [`LazySwappingConflicts`](@ref).
"""
function MAPF(
    g,
    edge_weights=weights(g);
    departures,
    arrivals,
    departure_times=fill(1, length(departures)),
    vertex_conflicts=LazyVertexConflicts(),
    edge_conflicts=LazySwappingConflicts(),
)
    return MAPF(
        g,
        edge_weights,
        departures,
        arrivals,
        departure_times,
        vertex_conflicts,
        edge_conflicts,
    )
end

## Modifiers

"""
    select_agents(mapf, agents)

Select a subset of agents and return a new `MAPF`.
"""
function select_agents(mapf::MAPF, agents)
    @assert issubset(agents, eachindex(mapf.departures))
    return MAPF(
        # Graph-related
        mapf.g,
        mapf.edge_weights,
        # Agents-related
        view(mapf.departures, agents),
        view(mapf.arrivals, agents),
        view(mapf.departure_times, agents),
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
    )
end

"""
    select_agents(mapf, A)

Select the first `A` agents and return a new `MAPF`.
"""
select_agents(mapf::MAPF, A::Integer) = select_agents(mapf, 1:A)
