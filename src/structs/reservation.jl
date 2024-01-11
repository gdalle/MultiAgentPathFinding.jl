"""
$(TYPEDEF)

Storage for vertices and edges that are known to be occupied.

# Fields

$(TYPEDFIELDS)
"""
mutable struct Reservation
    "set of tuples `(t, v)`"
    const forbidden_vertices::Set{Tuple{Int,Int}}
    "set of tuples `(t, u, v)`"
    const forbidden_edges::Set{Tuple{Int,Int,Int}}
    "maximum time of all forbidden vertices (mutable)"
    max_time::Int
end

"""
    Reservation()

Create an empty reservation.
"""
function Reservation()
    empty_forbidden_vertices = Set{Tuple{Int,Int}}()
    empty_forbidden_edges = Set{Tuple{Int,Int,Int}}()
    max_time = 0
    return Reservation(empty_forbidden_vertices, empty_forbidden_edges, max_time)
end

"""
    max_time(reservation)

Return the maximum time of all forbidden vertices in a reservation.
"""
max_time(reservation::Reservation) = reservation.max_time

"""
    is_forbidden_vertex(reservation, t, v)

Check whether vertex `v` is occupied at time `t` in a reservation.
"""
function is_forbidden_vertex(reservation::Reservation, t, v)
    return (t, v) in reservation.forbidden_vertices
end

"""
    is_forbidden_edge(reservation, t, u, v)

Check whether edge `(u, v)` is occupied at time `t` in a reservation.
"""
function is_forbidden_edge(reservation::Reservation, t, u, v)
    return (t, u, v) in reservation.forbidden_edges
end

"""
    compute_reservation(solution, mapf[; agents])

Compute a `Reservation` based on the vertices and edges occupied by a solution (or a subset of its `agents`).
"""
function compute_reservation(solution::Solution, mapf::MAPF, agents=1:nb_agents(mapf))
    reservation = Reservation()
    for a in agents
        timed_path = solution[a]
        update_reservation!(reservation, timed_path, mapf, a)
    end
    return reservation
end

"""
    update_reservation!(reservation, timed_path, mapf)

Add the vertices and edges occupied by a timed path to a reservation.
"""
function update_reservation!(reservation::Reservation, timed_path::TimedPath, mapf::MAPF, a)
    length(timed_path) > 0 || return nothing
    for t in departure_time(timed_path):arrival_time(timed_path)
        v = vertex_at_time(timed_path, t)
        for vv in mapf.vertex_conflicts[v]
            push!(reservation.forbidden_vertices, (t, vv))
        end
    end
    for t in departure_time(timed_path):(arrival_time(timed_path) - 1)
        u, v = edge_at_time(timed_path, t)
        for (uu, vv) in mapf.edge_conflicts[(u, v)]
            push!(reservation.forbidden_edges, (t, uu, vv))
        end
    end
    if arrival_time(timed_path) > reservation.max_time
        reservation.max_time = arrival_time(timed_path)
    end
    return nothing
end
