function compute_reservation(solution::Solution, mapf::MAPF; agents=1:nb_agents(mapf))
    reservation = Reservation()
    for a in agents
        path = solution[a]
        update_reservation!(reservation, path, mapf::MAPF)
    end
    return reservation
end

function update_reservation!(reservation::Reservation, path::Path, mapf::MAPF)
    for (t, v) in path
        for g in mapf.group_memberships[v]
            for w in mapf.conflict_groups[g]
                push!(reservation, (t, w))
            end
        end
    end
    return nothing
end
