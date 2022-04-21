function random_neighborhood(mapf::MAPF, N)
    return sample(1:nb_agents(mapf), N; replace=false)
end

function conflicting_neighborhood(solution::Solution, mapf::MAPF)
    A = nb_agents(mapf)
    neighborhood = Set{Int}()
    for a in 1:A
        for b in 1:(a - 1)
            if have_conflict(a, b, solution, mapf)
                push!(neighborhood, a)
                push!(neighborhood, b)
                break
            end
        end
    end
    return collect(neighborhood)
end

function remove_agents!(solution, agents)
    backup = Dict(a => solution[a] for a in agents)
    for a in agents
        solution[a] = Path()
    end
    return backup
end

function large_neighborhood_search!(
    solution::Solution, mapf::MAPF; N=1, steps=10, progress=true
)
    @assert is_feasible(solution, mapf)
    cost = flowtime(solution, mapf)
    if progress
        p = Progress(steps; desc="LNS steps: ")
    end
    for _ in 1:steps
        if progress
            next!(p)
        end
        agents = random_neighborhood(mapf, N)
        backup = remove_agents!(solution, agents)
        cooperative_astar!(solution, agents, mapf)
        new_cost = flowtime(solution, mapf)
        if is_feasible(solution, mapf) && new_cost < cost  # keep
            cost = new_cost
        else  # revert
            for a in agents
                solution[a] = backup[a]
            end
        end
    end
    return solution
end

function large_neighborhood_search(mapf::MAPF; N=1, steps=10, progress=true)
    solution = cooperative_astar(mapf, shuffle(1:nb_agents(mapf)))
    large_neighborhood_search!(solution, mapf; N=N, steps=steps, progress=progress)
    return solution
end
