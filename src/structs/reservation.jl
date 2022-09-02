"""
    Reservation

Storage for vertices and edges that are already occupied.

# Fields
- `forbidden_vertices::Set{Tuple{Int,Int}}`: set of tuples `(t,v)`
- `forbidden_edges::Set{Tuple{Int,Int}}`: set of tuples `(t,e)`
"""
struct Reservation
    forbidden_vertices::Set{Tuple{Int,Int}}
    forbidden_edges::Set{Tuple{Int,Int,Int}}
    arrivals_reached::Dict{Int,Int}
end

function Reservation()
    empty_forbidden_vertices = Set{Tuple{Int,Int}}()
    empty_forbidden_edges = Set{Tuple{Int,Int,Int}}()
    empty_arrivals_reached = Dict{Int,Int}()
    return Reservation(
        empty_forbidden_vertices, empty_forbidden_edges, empty_arrivals_reached
    )
end

function max_time(reservation::Reservation)
    return max(
        maximum(t for (t, v) in reservation.forbidden_vertices; init=0),
        maximum(values(reservation.arrivals_reached); init=0),
    )
end

function is_arrival_reached(reservation::Reservation, v)
    return haskey(reservation.arrivals_reached, v)
end

"""
    is_forbidden_vertex(reservation, t, v)

Check whether vertex `v` is occupied at time `t`.
"""
function is_forbidden_vertex(reservation::Reservation, t, v)
    return (t, v) in reservation.forbidden_vertices ||
           t >= get(reservation.arrivals_reached, v, typemax(Int))
end

"""
    is_forbidden_edge(reservation, t, u, v)

Check whether edge `(u, v)` is occupied at time `t`.
"""
function is_forbidden_edge(reservation::Reservation, t, u, v)
    return (t, u, v) in reservation.forbidden_edges ||
           (u == v && t >= get(reservation.arrivals_reached, v, typemax(Int)))
end

"""
    compute_reservation(solution, mapf; [agents])

Compute a [`Reservation`](@ref) based on the vertices and edges occupied by `solution` (or a subset of its `agents`).
"""
function compute_reservation(solution::Solution, mapf::MAPF; agents=1:nb_agents(mapf))
    reservation = Reservation()
    for a in agents
        timed_path = solution[a]
        update_reservation!(reservation, timed_path, mapf)
    end
    return reservation
end

"""
    update_reservation!(reservation, timed_path, mapf)

Add the vertices and edges occupied by `timed_path` to `reservation`.
"""
function update_reservation!(reservation::Reservation, timed_path::TimedPath, mapf::MAPF)
    length(timed_path) > 0 || return nothing
    for t in departure_time(timed_path):arrival_time(timed_path)
        v = vertex_at_time(timed_path, t)
        haskey(mapf.vertex_conflicts, v) || continue
        for vv in mapf.vertex_conflicts[v]
            push!(reservation.forbidden_vertices, (t, vv))
        end
    end
    for t in departure_time(timed_path):(arrival_time(timed_path) - 1)
        u, v = edge_at_time(timed_path, t)
        haskey(mapf.edge_conflicts, (u, v)) || continue
        for (uu, vv) in mapf.edge_conflicts[(u, v)]
            push!(reservation.forbidden_edges, (t, uu, vv))
        end
    end
    if mapf.stay_at_arrival
        reservation.arrivals_reached[last_vertex(timed_path)] = arrival_time(timed_path)
    end
    return nothing
end
