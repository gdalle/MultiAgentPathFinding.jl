function optimality_search!(
    solution::Solution,
    mapf::MAPF,
    spt_by_arr;
    optimality_timeout,
    neighborhood_size,
    show_progress,
)
    initial_cost = total_path_cost(solution, mapf)
    cost = initial_cost
    prog = ProgressUnknown(; desc="Optimality search steps: ", enabled=show_progress)
    total_time = 0.0
    moves_tried = 0
    moves_successful = 0
    if is_feasible(solution, mapf)
        while true
            moves_tried += 1
            τ1 = CPUtime_us()
            neighborhood_agents = random_neighborhood(mapf, neighborhood_size)
            backup = remove_agents!(solution, neighborhood_agents, mapf)
            cooperative_astar_from_trees!(solution, mapf, neighborhood_agents, spt_by_arr;)
            new_cost = total_path_cost(solution, mapf)
            if is_individually_feasible(solution, mapf) && new_cost < cost
                cost = new_cost
                moves_successful += 1
            else
                for a in neighborhood_agents
                    solution[a] = backup[a]
                end
            end
            τ2 = CPUtime_us()
            total_time += (τ2 - τ1) / 1e6
            if total_time > optimality_timeout
                break
            else
                next!(prog; showvalues=[(:cost, cost)])
            end
        end
    end
    stats = Dict(
        :optimality_moves_tried => moves_tried,
        :optimality_moves_successful => moves_successful,
        :optimality_initial_total_path_cost => initial_cost,
        :optimality_feasible => is_feasible(solution, mapf),
        :optimality_total_path_cost => total_path_cost(solution, mapf),
    )
    return stats
end

"""
$(SIGNATURES)

Run `cooperative_astar` and then reduce the total path cost with the MAPF-LNS algorithm from Li et al. (2021), see <https://www.ijcai.org/proceedings/2021/568>.

Returns a tuple containing a `Solution` and a dictionary of statistics.
"""
function optimality_search(
    mapf::MAPF,
    agents=1:nb_agents(mapf);
    optimality_timeout=2,
    neighborhood_size=10,
    show_progress=false,
)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = empty_solution(mapf)
    cooperative_astar_from_trees!(solution, mapf, agents, spt_by_arr; show_progress)
    stats = optimality_search!(
        solution, mapf, spt_by_arr; optimality_timeout, neighborhood_size, show_progress
    )
    return solution, stats
end
