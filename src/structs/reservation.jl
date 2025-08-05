"""
    Reservation

Keep track of which vertices and edges are known to be occupied and by which agent.

It does not have to be a physical occupation: some agent might be occupying a related vertex or edge which generates a conflict according to the rules of a `MAPF`.

Each undirected edge `(u, v)` is represented as `(min(u, v), max(u, v))` in the dictionary keys.

# Fields

$(TYPEDFIELDS)

# Note

The split between `single` and `multi` is done for efficiency reasons: there will be many more `single_occupied` than `multi_occupied`, so allocating a set for all of these would be wasteful (and using `Union{Int, Set{Int}}` would be type-unstable).
"""
struct Reservation
    "the maximum time of an occupation inside"
    max_time::Base.RefValue{Int}
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
end

"""
    Reservation()

Create an empty `Reservation`.
"""
function Reservation()
    max_time = Ref(0)
    single_occupied_vertices = Dict{Tuple{Int,Int},Int}()
    single_occupied_edges = Dict{Tuple{Int,Int,Int},Int}()
    multi_occupied_vertices = Dict{Tuple{Int,Int},Vector{Int}}()
    multi_occupied_edges = Dict{Tuple{Int,Int,Int},Vector{Int}}()
    arrival_vertices = Dict{Int,Tuple{Int,Int}}()
    return Reservation(
        max_time,
        single_occupied_vertices,
        single_occupied_edges,
        multi_occupied_vertices,
        multi_occupied_edges,
        arrival_vertices,
    )
end

"""
    extend!(reservation::Reservation, new_max_time::Integer)

Extend `reservation` so that it stretches until `new_max_time`.
"""
function extend!(reservation::Reservation, new_max_time::Integer)
    (; max_time, single_occupied_vertices, arrival_vertices) = reservation
    if new_max_time > max_time[]
        for (v, (_, a)) in pairs(arrival_vertices)
            for t in (max_time[] + 1):new_max_time
                single_occupied_vertices[t, v] = a
            end
        end
        max_time[] = new_max_time
    end
    return nothing
end

"""
    occupy!(reservation::Reservation, a::Integer, t::Integer, v::Integer)

Update `reservation` so that agent `a` occupies vertex `v` at time `t`.
"""
function occupy!(reservation::Reservation, a::Integer, t::Integer, v::Integer)
    (; single_occupied_vertices, multi_occupied_vertices) = reservation
    extend!(reservation, t)
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
    return nothing
end

"""
    occupy!(reservation::Reservation, a::Integer, t::Integer, u::Integer, v::Integer)

Update `reservation` so that agent `a` occupies edge `(u, v)` at time `t`.
"""
function occupy!(reservation::Reservation, a::Integer, t::Integer, u::Integer, v::Integer)
    (; single_occupied_edges, multi_occupied_edges) = reservation
    extend!(reservation, t)
    e = (min(u, v), max(u, v))
    if haskey(multi_occupied_edges, (t, e...))
        others = multi_occupied_edges[(t, e...)]
        if !(a in others)
            push!(others, a)
        end
    elseif haskey(single_occupied_edges, (t, e...))
        b = single_occupied_edges[(t, e...)]
        multi_occupied_edges[(t, e...)] = [b, a]
        delete!(single_occupied_edges, (t, e...))
    else
        reservation.single_occupied_edges[(t, e...)] = a
    end
    return nothing
end

"""
    arrive!(reservation::Reservation, a::Integer, t::Integer, v::Integer)

Update `reservation` so that agent `a` arrives vertex `v` at time `t` and never moves again.
"""
function arrive!(reservation::Reservation, a::Integer, t::Integer, v::Integer)
    (; max_time, arrival_vertices) = reservation
    extend!(reservation, t)
    @assert !haskey(arrival_vertices, v)
    arrival_vertices[v] = (t, a)
    for t_stay in (t + 1):max_time[]
        occupy!(reservation, a, t_stay, v)
    end
    return nothing
end

"""
    is_occupied_vertex(reservation::Reservation, t::Integer, v::Integer)

Check whether vertex `v` is occupied at time `t` in a reservation.
"""
function is_occupied_vertex(reservation::Reservation, t::Integer, v::Integer)
    (; max_time, single_occupied_vertices, multi_occupied_vertices, arrival_vertices) =
        reservation
    if t <= max_time[]
        return haskey(single_occupied_vertices, (t, v)) ||
               haskey(multi_occupied_vertices, (t, v))
    else
        return haskey(arrival_vertices, v)
    end
end

"""
    is_occupied_edge(reservation::Reservation, t::Integer, u::Integer, v::Integer)

Check whether edge `(u, v)` is occupied at time `t` in a reservation.
"""
function is_occupied_edge(reservation::Reservation, t::Integer, u::Integer, v::Integer)
    (; max_time, single_occupied_edges, multi_occupied_edges) = reservation
    e = (min(u, v), max(u, v))
    if t <= max_time[]
        return haskey(single_occupied_edges, (t, e...)) ||
               haskey(multi_occupied_edges, (t, e...))
    else
        return false
    end
end

"""
    is_safe_vertex_to_stop(reservation::Reservation, t::Integer, v::Integer)

Check whether vertex `v` is safe to stop time `t` in a reservation, which means that no one else crosses it afterwards.
"""
function is_safe_vertex_to_stop(reservation::Reservation, t::Integer, v::Integer)
    (; max_time, arrival_vertices) = reservation
    return !haskey(arrival_vertices, v) &&
           !any(is_occupied_vertex(reservation, s, v) for s in t:max_time[])
end

"""
    update_reservation!(reservation::Reservation, path::Path, a::Integer, mapf::MAPF)

Add the vertices and edges occupied by a path to a reservation.
"""
function update_reservation!(reservation::Reservation, path::Path, a::Integer, mapf::MAPF)
    (; vertex_conflicts, edge_conflicts) = mapf
    for (t, u) in enumerate(path)
        for uu in vertex_conflicts[u]
            occupy!(reservation, a, t, uu)
        end
    end
    for t in 1:(length(path) - 1)
        u, v = path[t], path[t + 1]
        for (uu, vv) in edge_conflicts[(u, v)]
            ee = (min(uu, vv), max(uu, vv))
            occupy!(reservation, a, t, ee...)
        end
    end
    u_arrival, t_arrival = last(path), length(path)
    for uu in vertex_conflicts[u_arrival]
        arrive!(reservation, a, t_arrival, uu)
    end
    return nothing
end

"""
    Reservation(solution::Solution, mapf::MAPF)

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
