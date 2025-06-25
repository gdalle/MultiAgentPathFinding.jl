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
    "`(t, v) -> [a1, a2]` where `a1, a2` are the multiple agents occupying `v` at time `t`"
    multi_occupied_vertices::Dict{Tuple{Int,Int},Vector{Int}}
    "`(t, u, v) -> [a1, a2]` where `a1, a2` are the multiple agents occupying `(u, v)` at time `t`"
    multi_occupied_edges::Dict{Tuple{Int,Int,Int},Vector{Int}}
    "`v -> (t, a)` where `a` is the agent whose arrival vertex is `v` and who owns it starting at time `t` (necessary for stay-at-target behavior)"
    arrival_vertices::Dict{Int,Tuple{Int,Int}}
    "`v -> [(t2, a1), (t2, a2)]` where the `ai` are additional agents visiting vertex `v` at times `ti`, once it is already owned as an arrival vertex"
    arrival_vertices_crossings::Dict{Int,Vector{Tuple{Int,Int}}}
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
    arrival_vertices = Dict{Int,Tuple{Int,Int}}()
    arrival_vertices_crossings = Dict{Int,Vector{Tuple{Int,Int}}}()
    return Reservation(
        single_occupied_vertices,
        single_occupied_edges,
        multi_occupied_vertices,
        multi_occupied_edges,
        arrival_vertices,
        arrival_vertices_crossings,
    )
end

"""
$(TYPEDSIGNATURES)

Update `reservation` so that agent `a` occupies vertex `v` at time `t`.
"""
function occupy!(reservation::Reservation, a::Integer, t::Integer, v::Integer)
    (;
        single_occupied_vertices,
        multi_occupied_vertices,
        arrival_vertices,
        arrival_vertices_crossings,
    ) = reservation
    if haskey(multi_occupied_vertices, (t, v))
        others = multi_occupied_vertices[(t, v)]
        if !(a in others)
            push!(others, a)
        end
    elseif haskey(single_occupied_vertices, (t, v))
        b = single_occupied_vertices[(t, v)]
        multi_occupied_vertices[(t, v)] = [b, a]
        delete!(single_occupied_vertices, (t, v))
    else
        single_occupied_vertices[(t, v)] = a
    end
    # relies on the fact that occupy! will be called before arrive!
    if haskey(arrival_vertices, v) && arrival_vertices[v][1] <= t
        if haskey(arrival_vertices_crossings, v)
            push!(arrival_vertices_crossings[v], (t, a))
        else
            arrival_vertices_crossings[v] = [(t, a)]
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Update `reservation` so that agent `a` occupies edge `(u, v)` at time `t`.
"""
function occupy!(reservation::Reservation, a::Integer, t::Integer, u::Integer, v::Integer)
    (; single_occupied_edges, multi_occupied_edges) = reservation
    if haskey(multi_occupied_edges, (t, u, v))
        others = multi_occupied_edges[(t, u, v)]
        if !(a in others)
            push!(others, a)
        end
    elseif haskey(single_occupied_edges, (t, u, v))
        b = single_occupied_edges[(t, u, v)]
        multi_occupied_edges[(t, u, v)] = [b, a]
        delete!(single_occupied_edges, (t, u, v))
    else
        reservation.single_occupied_edges[(t, u, v)] = a
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Update `reservation` so that agent `a` arrives vertex `v` at time `t` and never moves again.
"""
function arrive!(reservation::Reservation, a::Integer, t::Integer, v::Integer)
    (; arrival_vertices) = reservation
    @assert !haskey(arrival_vertices, v)
    arrival_vertices[v] = (t, a)
    return nothing
end

"""
$(TYPEDSIGNATURES)

Check whether vertex `v` is occupied at time `t` in a reservation.
"""
function is_occupied_vertex(reservation::Reservation, t::Integer, v::Integer)
    (; single_occupied_vertices, multi_occupied_vertices, arrival_vertices) = reservation
    return haskey(single_occupied_vertices, (t, v)) ||
           haskey(multi_occupied_vertices, (t, v)) ||
           (haskey(arrival_vertices, v) && arrival_vertices[v][1] <= t)
end

"""
$(TYPEDSIGNATURES)

Check whether edge `(u, v)` is occupied at time `t` in a reservation.
"""
function is_occupied_edge(reservation::Reservation, t::Integer, u::Integer, v::Integer)
    (; single_occupied_edges, multi_occupied_edges) = reservation
    return haskey(single_occupied_edges, (t, u, v)) ||
           haskey(multi_occupied_edges, (t, u, v))
end

"""
$(TYPEDSIGNATURES)

Add the vertices and edges occupied by a path to a reservation.
"""
function update_reservation!(reservation::Reservation, path::Path, a::Integer, mapf::MAPF)
    (; vertex_conflicts, edge_conflicts) = mapf
    for t in 1:(length(path) - 1)
        u, v = path[t], path[t + 1]
        for uu in vertex_conflicts[u]
            occupy!(reservation, a, t, uu)
        end
        for (uu, vv) in edge_conflicts[(u, v)]
            occupy!(reservation, a, t, uu, vv)
        end
    end
    u_arrival, t_arrival = last(path), length(path)
    for uu in vertex_conflicts[u_arrival]
        arrive!(reservation, a, t_arrival, uu)
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Compute a `Reservation` based on the vertices and edges occupied by `solution`.
Conflicts are computed within `mapf`.
"""
function Reservation(solution::Solution, mapf::MAPF)
    (; paths) = solution
    reservation = Reservation()
    for a in keys(paths)
        update_reservation!(reservation, paths[a], a, mapf)
    end
    return reservation
end
