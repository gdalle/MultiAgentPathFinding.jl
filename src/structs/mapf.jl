"""
$(TYPEDEF)

Instance of a Multi-Agent Path Finding problem with custom conflict rules.

# Constructors

    MAPF(
        g::AbstractGraph, departures::Vector{Int}, arrivals::Vector{Int};
        vertex_conflicts=LazyVertexConflicts(), edge_conflicts=LazyEdgeConflicts()
    )

# Fields

$(TYPEDFIELDS)
"""
struct MAPF{W,VC,EC}
    # Graph-related
    "underlying weighted graph"
    g::SimpleWeightedGraph{Int,W}
    # Agents-related
    "agent departure vertices"
    departures::Vector{Int}
    "agent arrival vertices"
    arrivals::Vector{Int}
    # Constraints-related
    "indexable object linking vertices to their incompatibility set"
    vertex_conflicts::VC
    "indexable object linking edges (as tuples) to their incompatibility set"
    edge_conflicts::EC

    function MAPF(
        g::AbstractGraph,
        departures::Vector{Int},
        arrivals::Vector{Int};
        vertex_conflicts::VC=LazyVertexConflicts(),
        edge_conflicts::EC=LazySwappingConflicts(),
    ) where {VC,EC}
        @assert !is_directed(g)
        @assert length(departures) == length(arrivals)
        @assert all(Base.Fix1(has_vertex, g), departures)
        @assert all(Base.Fix1(has_vertex, g), arrivals)
        # TODO: add more checks
        gw = SimpleWeightedGraph(g)
        W = weighttype(gw)
        return new{W,VC,EC}(gw, departures, arrivals, vertex_conflicts, edge_conflicts)
    end
end

function Base.show(io::IO, mapf::MAPF{G}) where {G}
    return print(
        io,
        "Multi-Agent Path Finding problem with $(nv(mapf.g)) vertices, $(ne(mapf.g)) edges and $(nb_agents(mapf)) agents",
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

Lazy dict-like storage for the mapping `(u, v) -> [(v, u)]`.
"""
struct LazySwappingConflicts end

Base.getindex(::LazySwappingConflicts, (u, v)::Tuple{Integer,Integer}) = ((u, v), (v, u))

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
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
    )
end
