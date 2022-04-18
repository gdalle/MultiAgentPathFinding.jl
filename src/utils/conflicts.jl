function find_conflict(a, b, solution, mapf::MAPF)
    path_a = solution[a]
    path_b = solution[b]
    t0b = mapf.starting_times[b]
    for (ta, va) in path_a
        kb = ta + 1 - t0b
        if 1 <= kb <= length(path_b)
            (tb, vb) = path_b[kb]
            for ga in mapf.group_memberships[va]
                if vb in mapf.conflict_groups[ga]
                    return (a=a, b=b, t=ta, g=ga)
                end
            end
        end
    end
    return nothing
end

function have_conflict(a, b, solution, mapf::MAPF)
    return !isnothing(find_conflict(a, b, solution, mapf))
end

function nb_conflicts(solution, a, mapf)
    A = nb_agents(mapf)
    c = 0
    for b in 1:A
        b != a || continue
        if have_conflict(a, b, solution, mapf)
            c += 1
        end
    end
    return c
end

function nb_conflicting_pairs(solution, mapf::MAPF)
    p = 0
    for a in 1:nb_agents(mapf), b in 1:(a - 1)
        p += have_conflict(a, b, solution, mapf)
    end
    return p
end

function find_conflict(solution, mapf::MAPF)
    A = nb_agents(mapf)
    for a in 1:A, b in 1:(a - 1)
        conflict = find_conflict(a, b, solution, mapf)
        isnothing(conflict) || return conflict
    end
    return nothing
end

function has_conflict(solution, mapf::MAPF)
    return !isnothing(find_conflict(solution, mapf))
end
