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
end

function Reservation()
    empty_forbidden_vertices = Set{Tuple{Int,Int}}()
    empty_forbidden_edges = Set{Tuple{Int,Int,Int}}()
    return Reservation(empty_forbidden_vertices, empty_forbidden_edges)
end

"""
    is_forbidden_vertex(reservation, t, v)

Check whether vertex `v` is occupied at time `t`.
"""
function is_forbidden_vertex(res::Reservation, t, v)
    return (t, v) in res.forbidden_vertices
end

"""
    is_forbidden_edge(reservation, t, u, v)

Check whether edge `(u, v)` is occupied at time `t`.
"""
function is_forbidden_edge(res::Reservation, t, u, v)
    return (t, u, v) in res.forbidden_edges
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
    return nothing
end
