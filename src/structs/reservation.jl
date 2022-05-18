"""
    Reservation

Storage for already-occupied vertices and edges.

# Fields
- `forbidden_vertices`: set of tuples `(t,v)`
- `forbidden_edges`: set of tuples `(t,e)`
"""
struct Reservation
    forbidden_vertices::Set{Tuple{Int,Int}}
    forbidden_edges::Set{Tuple{Int,Int}}
end

Reservation() = Reservation(Set{Tuple{Int,Int}}(), Set{Tuple{Int,Int}}())

function is_forbidden_vertex(res::Reservation, t::Integer, v::Integer)
    return (t, v) in res.forbidden_vertices
end

is_forbidden_edge(res::Reservation, t::Integer, e::Integer) = (t, e) in res.forbidden_edges

function compute_reservation(solution::Solution, mapf::MAPF; agents=1:nb_agents(mapf))
    reservation = Reservation()
    for a in agents
        path = solution[a]
        update_reservation!(reservation, path, mapf::MAPF)
    end
    return reservation
end

function update_reservation!(reservation::Reservation, path::Path, mapf::MAPF)
    for (t, u) in path
        for g in mapf.vertex_group_memberships[u]
            for v in mapf.vertex_groups[g]
                push!(reservation.forbidden_vertices, (t, v))
            end
        end
    end
    return nothing
end
