struct MissingSolutionError <: Exception
    msg::String
end

"""
    read_benchmark_solution(scen::BenchmarkScenario)

Read a solution from an automatically downloaded text file.

Return a named tuple `(; lower_cost, solution_cost, paths_coord_list)` where:

- `lower_cost` is a (supposedly) proven lower bound on the optimal cost
- `solution_cost` is the cost of the provided solution
- `paths_coord_list` is a vector of agent trajectories, each one being encoded as a vector of coordinate tuples `(i, j)` (with `(1, 1)` as the upper-left corner)
"""
function read_benchmark_solution(scen::BenchmarkScenario)
    (; instance, scen_type, type_id, agents) = scen
    sol_path = joinpath(@datadep_str("mapf-sol-$instance"), "$instance.csv")
    sol_df = DataFrame(CSV.File(sol_path))
    right_scen = (sol_df[!, :scen_type] .== scen_type) .& (sol_df[!, :type_id] .== type_id)
    sol_df = sol_df[right_scen, :]
    if size(sol_df, 1) == 0
        throw(
            MissingSolutionError(
                "Scenario $scen_type-$type_id does not exist for instance $instance"
            ),
        )
    end
    agents = if isnothing(agents)
        maximum(sol_df[!, :agents])
    else
        agents
    end
    right_agents = sol_df[!, :agents] .== agents
    sol_df = sol_df[right_agents, :]
    if size(sol_df, 1) == 0
        throw(
            MissingSolutionError(
                "Scenario $scen_type-$type_id for instance $instance does not have a best known solution with $agents agents",
            ),
        )
    end
    sol = only(eachrow(sol_df))
    plan = sol[:solution_plan]
    if ismissing(plan)
        throw(
            MissingSolutionError(
                "Scenario $scen_type-$type_id for instance $instance does not have a best known solution with $agents agents",
            ),
        )
    end
    paths_string_list = split(plan, "\n")

    agent_list = read_benchmark_scenario(scen)

    paths_coord_list = map(1:agents, paths_string_list) do a, path_string
        start = (agent_list[a].start_i, agent_list[a].start_j)
        goal = (agent_list[a].goal_i, agent_list[a].goal_j)
        location = start
        path_coord = [location]
        for c in path_string
            if c == 'u'  # up means y+1 means i+1
                location = location .+ (1, 0)
            elseif c == 'd'  # down means y-1 means i-1
                location = location .+ (-1, 0)
            elseif c == 'l'  # left means x-1 means j-1
                location = location .+ (0, -1)
            elseif c == 'r'  # right means x+1 means j+1
                location = location .+ (0, 1)
            elseif c == 'w'  # wait means nothing changes
                location = location .+ (0, 0)
            end
            push!(path_coord, location)
        end
        @assert path_coord[begin] == start
        @assert path_coord[end] == goal
        return path_coord
    end

    return (;
        lower_cost=sol[:lower_cost],
        solution_cost=sol[:solution_cost],
        paths_coord_list=paths_coord_list,
    )
end
