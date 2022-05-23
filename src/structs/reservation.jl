"""
    Reservation

Storage for vertices and edges that are already occupied.

# Fields
- `forbidden_vertices::Set{Tuple{Int,Int}}`: set of tuples `(t,v)`
- `forbidden_edges::Set{Tuple{Int,Int}}`: set of tuples `(t,e)`
"""
struct Reservation
    forbidden_vertices::Set{Tuple{Int,Int}}
    forbidden_edges::Set{Tuple{Int,Int}}
end

Reservation() = Reservation(Set{Tuple{Int,Int}}(), Set{Tuple{Int,Int}}())

"""
    is_forbidden_vertex(reservation, t, v)

Check whether vertex `v` is occupied at time `t`.
"""
function is_forbidden_vertex(res::Reservation, t::Integer, v::Integer)
    return (t, v) in res.forbidden_vertices
end

"""
    is_forbidden_edge(reservation, t, e)

Check whether edge `e` is occupied at time `t`.
"""
is_forbidden_edge(res::Reservation, t::Integer, e::Integer) = (t, e) in res.forbidden_edges

"""
    compute_reservation(solution, mapf; [agents])

Compute a [`Reservation`](@ref) based on the vertices and edges occupied by `solution` (or a subset of its `agents`).
"""
function compute_reservation(solution::Solution, mapf::MAPF; agents=1:nb_agents(mapf))
    reservation = Reservation()
    for a in agents
        timed_path = solution[a]
        update_reservation!(reservation, timed_path, mapf::MAPF)
    end
    return reservation
end

"""
    update_reservation!(reservation, timed_path, mapf)

Add the vertices and edges occupied by `timed_path` to `reservation`.
"""
function update_reservation!(reservation::Reservation, timed_path::TimedPath, mapf::MAPF)
    (; t0, path) = timed_path
    for (k, u) in enumerate(path)
        for v in mapf.vertex_conflicts[u]
            push!(reservation.forbidden_vertices, (t0 + k - 1, v))
        end
    end
    return nothing
end
