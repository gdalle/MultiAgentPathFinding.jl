"""
$(TYPEDEF)

Instance of a Multi-Agent Path Finding problem with custom conflict rules.

# Constructors

    MAPF(
        graph::AbstractGraph,
        departures::Vector{Int},
        arrivals::Vector{Int};
        vertex_conflicts=LazyVertexConflicts(),
        edge_conflicts=LazyEdgeConflicts()
    )

# Fields

$(TYPEDFIELDS)
"""
struct MAPF{W,VC,EC}
    # Graph-related
    "underlying weighted graph"
    graph::SimpleWeightedGraph{Int,W}
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
end

function MAPF(
    graph::AbstractGraph,
    departures::Vector{Int},
    arrivals::Vector{Int};
    vertex_conflicts=LazyVertexConflicts(),
    edge_conflicts=LazySwappingConflicts(),
)
    @assert !is_directed(graph)
    @assert length(departures) == length(arrivals)
    @assert all(Base.Fix1(has_vertex, graph), departures)
    @assert all(Base.Fix1(has_vertex, graph), arrivals)
    # TODO: add more checks
    weighted_graph = SimpleWeightedGraph(graph)
    return MAPF(weighted_graph, departures, arrivals, vertex_conflicts, edge_conflicts)
end

function Base.show(io::IO, mapf::MAPF{G}) where {G}
    return print(
        io,
        "Multi-Agent Path Finding problem with $(nv(mapf.graph)) vertices, $(ne(mapf.graph)) edges and $(nb_agents(mapf)) agents",
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

Lazy dict-like storage for the mapping `(u, v) -> [(u, v),]` (which also forbids `(v, u)` since the graph is undirected).
"""
struct LazySwappingConflicts end

function Base.getindex(::LazySwappingConflicts, (u, v)::Tuple{Integer,Integer})
    return ((u, v),)
end

## Modifiers

"""
$(TYPEDSIGNATURES)

Select a subset of agents in `mapf` and return a new `MAPF`.
"""
function select_agents(mapf::MAPF, agents::AbstractVector{<:Integer})
    @assert issubset(agents, eachindex(mapf.departures))
    return MAPF(
        # Graph-related
        mapf.graph,
        # Agents-related
        mapf.departures[agents],
        mapf.arrivals[agents],
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
    )
end
