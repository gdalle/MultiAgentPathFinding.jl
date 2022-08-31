function colliding_pairs(solution::Solution, mapf::MAPF; tol=0)
    cp = 0
    for a1 in 1:nb_agents(mapf), a2 in 1:(a1 - 1)
        if find_conflict(a1, a2, solution, mapf; tol=tol) !== nothing
            cp += 1
        end
    end
    return cp
end

function feasibility_search!(
    solution::Solution,
    mapf::MAPF,
    edge_weights_vec::AbstractVector{<:Real},
    spt_by_dest::Dict{Int,<:ShortestPathTree};
    neighborhood_size,
    conflict_price,
    conflict_price_increase,
    show_progress,
)
    A = nb_agents(mapf)
    pathless_agents = shuffle([a for a in 1:A if length(solution[a]) == 0])
    cooperative_astar!(
        solution,
        mapf,
        pathless_agents,
        edge_weights_vec,
        spt_by_dest;
        conflict_price=conflict_price,
    )
    cp = colliding_pairs(solution, mapf)
    prog = ProgressUnknown("Feasibility search steps: "; enabled=show_progress)
    while !is_feasible(solution, mapf)
        next!(prog; showvalues=[(:colliding_pairs, cp)])
        neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
        backup = remove_agents!(solution, neighborhood_agents, mapf)
        cooperative_astar!(
            solution,
            mapf,
            neighborhood_agents,
            edge_weights_vec,
            spt_by_dest;
            conflict_price=conflict_price,
        )
        new_cp = colliding_pairs(solution, mapf)
        if is_feasible(solution, mapf) || (new_cp <= cp)  # keep
            cp = new_cp
        else  # revert
            for a in neighborhood_agents
                solution[a] = backup[a]
            end
        end
        conflict_price *= (one(conflict_price_increase) + conflict_price_increase)
    end
    return solution
end

function feasibility_search(
    mapf::MAPF,
    edge_weights_vec::AbstractVector{<:Real}=mapf.edge_weights_vec;
    neighborhood_size=10,
    conflict_price=1.0,
    conflict_price_increase=1e-2,
    show_progress=false,
)
    spt_by_dest = dijkstra_by_destination(mapf, edge_weights_vec)
    solution = independent_dijkstra(mapf, spt_by_dest)
    feasibility_search!(
        solution,
        mapf,
        edge_weights_vec,
        spt_by_dest;
        neighborhood_size=neighborhood_size,
        conflict_price=conflict_price,
        conflict_price_increase=conflict_price_increase,
        show_progress=show_progress,
    )
    return solution
end
