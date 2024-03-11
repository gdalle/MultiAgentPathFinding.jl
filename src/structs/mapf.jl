"""
$(TYPEDEF)

Instance of a Multi-Agent Path Finding problem with custom conflict rules.

# Fields

$(TYPEDFIELDS)

# Note

Agents appear at their departure vertex when the departure time comes, and they disappear as soon as they have reached the arrival vertex.
"""
struct MAPF{W<:Real,G<:AbstractGraph{Int},M,VC,EC}

    # Graph-related
    "underlying graph"
    g::G
    "edge costs, typically stored as a matrix with eltype `W`"
    edge_costs::M

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
        edge_costs::M,
        departures,
        arrivals,
        departure_times,
        vertex_conflicts::VC,
        edge_conflicts::EC,
    ) where {G,M,VC,EC}
        @assert length(departures) == length(arrivals) == length(departure_times)
        # TODO: add more checks
        return new{eltype(M),G,M,VC,EC}(
            g,
            edge_costs,
            departures,
            arrivals,
            departure_times,
            vertex_conflicts,
            edge_conflicts,
        )
    end
end

"""
    edge_cost(edge_costs::AbstractMatrix, u, v)
    edge_cost(edge_costs::AbstractMatrix, u, v, a, t)

Return the cost of edge `(u, v)` for agent `a` at time `t` when the cost storage `edge_costs` is a matrix (hence agent- and time-independent).

This method, as well as `Base.eltype`, must be overridden for other storage formats.
"""
edge_cost(edge_costs::AbstractMatrix, u::Integer, v::Integer, args...) = edge_costs[u, v]

edge_cost(mapf::MAPF, args...) = edge_cost(mapf.edge_costs, args...)

## Default constructor

"""
$(TYPEDSIGNATURES)

User-friendly constructor for a `MAPF`.

Departure times default to 1 for every agent, vertex conflicts default to [`LazyVertexConflicts`](@ref) and edge conflicts to [`LazySwappingConflicts`](@ref).
"""
function MAPF(
    g::AbstractGraph,
    edge_costs=weights(g);
    departures::AbstractVector{<:Integer},
    arrivals::AbstractVector{<:Integer},
    departure_times=fill(1, length(departures))::AbstractVector{<:Integer},
    vertex_conflicts=LazyVertexConflicts(),
    edge_conflicts=LazySwappingConflicts(),
)
    return MAPF(
        g,
        edge_costs,
        departures,
        arrivals,
        departure_times,
        vertex_conflicts,
        edge_conflicts,
    )
end

## Display

function Base.show(io::IO, mapf::MAPF{W,G}) where {W,G}
    return print(
        io,
        """Multi-Agent Path Finding problem
        Graph type: $G with $W costs
        Graph size: $(nv(mapf.g)) vertices and $(ne(mapf.g)) edges
        Nb of agents: $(nb_agents(mapf))""",
    )
end

## Access

"""
$(TYPEDSIGNATURES)

Count the number of agents in `mapf`.
"""
nb_agents(mapf::MAPF) = length(mapf.departures)

## Default conflicts

"""
$(TYPEDEF)

Lazy dict-like storage for the mapping `v -> [v]`.
"""
struct LazyVertexConflicts end

Base.getindex(::LazyVertexConflicts, v::Integer) = (v,)

"""
$(TYPEDEF)

Lazy dict-like storage for the mapping `(u, v) -> [(u, v)]`.
"""
struct LazyEdgeConflicts end

Base.getindex(::LazyEdgeConflicts, (u, v)::Tuple{T,T}) where {T<:Integer} = ((u, v),)

"""
$(TYPEDEF)

Lazy dict-like storage for the mapping `(u, v) -> [(v, u)]`.
"""
struct LazySwappingConflicts end

Base.getindex(::LazySwappingConflicts, (u, v)::Tuple{T,T}) where {T<:Integer} = ((v, u),)

## Modifiers

"""
$(TYPEDSIGNATURES)

Select a subset of agents in `mapf` and return a new `MAPF`.
"""
function select_agents(mapf::MAPF, agents::AbstractVector{<:Integer})
    @assert issubset(agents, eachindex(mapf.departures))
    return MAPF(
        # Graph-related
        mapf.g,
        mapf.edge_costs,
        # Agents-related
        view(mapf.departures, agents),
        view(mapf.arrivals, agents),
        view(mapf.departure_times, agents),
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
    )
end
