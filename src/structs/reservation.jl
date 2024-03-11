"""
$(TYPEDEF)

Keep track of which vertices and edges are known to be occupied and by whom.

It does not have to be a physical occupation: some agent might be occupying a related vertex or edge which generates a conflict.

# Fields

$(TYPEDFIELDS)

# Note

The split between `single` and `multi` is done for efficiency reasons: there will be many more `single_occupied` than `multi_occupied`, so allocating a set for all of these would be wasteful (and using `Union{Int, Set{Int}}` would be type-unstable).
"""
struct Reservation
    "`(t, v) -> a` where `a` is the only agent occupying `v` at time `t`"
    single_occupied_vertices::Dict{Tuple{Int,Int},Int}
    "`(t, u, v) -> a` where `a` is the only agent occupying `(u, v)` at time `t`"
    single_occupied_edges::Dict{Tuple{Int,Int,Int},Int}
    "maximum time of all occupied vertices (mutable)"
    "`(t, v) -> [a1, a2]` where `a1, a2` are the multiple agents occupying `v` at time `t`"
    multi_occupied_vertices::Dict{Tuple{Int,Int},Vector{Int}}
    "`(t, u, v) -> [a1, a2]` where `a1, a2` are the multiple agents occupying `(u, v)` at time `t`"
    multi_occupied_edges::Dict{Tuple{Int,Int,Int},Vector{Int}}
    "maximum time of all occupied vertices (mutable)"
end

"""
$(TYPEDSIGNATURES)

Create an empty `Reservation`.
"""
function Reservation()
    single_occupied_vertices = Dict{Tuple{Int,Int},Int}()
    single_occupied_edges = Dict{Tuple{Int,Int,Int},Int}()
    multi_occupied_vertices = Dict{Tuple{Int,Int},Vector{Int}}()
    multi_occupied_edges = Dict{Tuple{Int,Int,Int},Vector{Int}}()
    return Reservation(
        single_occupied_vertices,
        single_occupied_edges,
        multi_occupied_vertices,
        multi_occupied_edges,
    )
end

"""
$(TYPEDSIGNATURES)

Update `reservation` so that agent `a` occupies vertex `v` at time `t`.
"""
function occupy!(reservation::Reservation, a::Integer, t::Integer, v::Integer)
    if haskey(reservation.multi_occupied_vertices, (t, v))
        others = reservation.multi_occupied_vertices[(t, v)]
        if !(a in others)
            push!(others, a)
        end
    elseif haskey(reservation.single_occupied_vertices, (t, v))
        b = reservation.single_occupied_vertices[(t, v)]
        reservation.multi_occupied_vertices[(t, v)] = [b, a]
        delete!(reservation.single_occupied_vertices, (t, v))
    else
        reservation.single_occupied_vertices[(t, v)] = a
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Update `reservation` so that agent `a` occupies edge `(u, v)` at time `t`.
"""
function occupy!(reservation::Reservation, a::Integer, t::Integer, u::Integer, v::Integer)
    if haskey(reservation.multi_occupied_edges, (t, u, v))
        others = reservation.multi_occupied_edges[(t, u, v)]
        if !(a in others)
            push!(others, a)
        end
    elseif haskey(reservation.single_occupied_edges, (t, u, v))
        b = reservation.single_occupied_edges[(t, u, v)]
        reservation.multi_occupied_edges[(t, u, v)] = [b, a]
        delete!(reservation.single_occupied_edges, (t, u, v))
    else
        reservation.single_occupied_edges[(t, u, v)] = a
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Check whether vertex `v` is occupied at time `t` in a reservation.
"""
function is_occupied_vertex(reservation::Reservation, t::Integer, v::Integer)
    return haskey(reservation.single_occupied_vertices, (t, v)) ||
           haskey(reservation.multi_occupied_vertices, (t, v))
end

"""
$(TYPEDSIGNATURES)

Check whether edge `(u, v)` is occupied at time `t` in a reservation.
"""
function is_occupied_edge(reservation::Reservation, t::Integer, u::Integer, v::Integer)
    return haskey(reservation.single_occupied_edges, (t, u, v)) ||
           haskey(reservation.multi_occupied_edges, (t, u, v))
end

"""
$(TYPEDSIGNATURES)

Add the vertices and edges occupied by a timed path to a reservation.
"""
function update_reservation!(
    reservation::Reservation, timed_path::TimedPath, a::Integer, mapf::MAPF
)
    for t in departure_time(timed_path):arrival_time(timed_path)
        v = vertex_at_time(timed_path, t)
        for vv in mapf.vertex_conflicts[v]
            occupy!(reservation, a, t, vv)
        end
    end
    for t in departure_time(timed_path):(arrival_time(timed_path) - 1)
        u, v = edge_at_time(timed_path, t)
        for (uu, vv) in mapf.edge_conflicts[(u, v)]
            occupy!(reservation, a, t, uu, vv)
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Compute a `Reservation` based on the vertices and edges occupied by `solution`.
Conflicts are computed within `mapf`.
"""
function Reservation(solution::Solution, mapf::MAPF)
    reservation = Reservation()
    for a in keys(solution.timed_paths)
        update_reservation!(reservation, solution.timed_paths[a], a, mapf)
    end
    return reservation
end
