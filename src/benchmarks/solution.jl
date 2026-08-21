struct MissingSolutionError <: Exception
    msg::String
end

const _TRACKER_API_URL = "https://fe2410d1.pathfinding.ai/api"

const _SOLUTION_COLUMNS = [
    :scen_type, :type_id, :agents, :lower_cost, :solution_cost, :solution_plan
]

"""
    _tracker_scenarios(instance)

List the scenario records for `instance` (e.g. `"empty-8-8"`) from the MAPF tracker API, each
one containing (among other things) its Mongo `"id"`, `"scen_type"` and `"type_id"`.
"""
function _tracker_scenarios(instance::AbstractString)
    io = IOBuffer()
    Downloads.download("$_TRACKER_API_URL/scenario", io)
    all_scenarios = JSON.parse(String(take!(io)))
    return filter(s -> s["map_name"] == instance, all_scenarios)
end

"""
    _tracker_results(scenario_id; page_size)

Fetch every instance (agent count) of a tracker scenario, together with its best known
solution, handling the API's pagination transparently.
"""
function _tracker_results(scenario_id::AbstractString; page_size::Integer=500)
    results = Dict{String,Any}[]
    skip = 0
    while true
        body = JSON.json(
            Dict(
                "scenario" => scenario_id,
                "solutions" => true,
                "limit" => page_size,
                "skip" => skip,
            ),
        )
        io = IOBuffer()
        Downloads.request(
            "$_TRACKER_API_URL/bulk/results";
            method="POST",
            headers=["Content-Type" => "application/json"],
            input=IOBuffer(body),
            output=io,
        )
        page = JSON.parse(String(take!(io)))
        append!(results, page)
        length(page) < page_size && break
        skip += page_size
    end
    return results
end

"""
    _expand_plan(plan)

Expand a run-length encoded solution plan such as `"2rdr2d2r"`, as returned by the MAPF tracker
API, into one character per move (`"rrdrddrr"`), as expected when parsing solution plans.
"""
function _expand_plan(plan::AbstractString)
    expanded = IOBuffer()
    repeats = 0
    for c in plan
        if isdigit(c)
            repeats = 10 * repeats + (c - '0')
        else
            write(expanded, repeat(c, max(repeats, 1)))
            repeats = 0
        end
    end
    return String(take!(expanded))
end

_expand_plans(plan::AbstractString) = join(_expand_plan.(split(plan, "\n")), "\n")
_expand_plans(::Missing) = missing

"""
    _download_tracker_solutions(instance)

Download every known best solution for `instance` from the MAPF tracker API and assemble them
into a `DataFrame` with the same columns as the discontinued per-instance solution CSV files.
"""
function _download_tracker_solutions(instance::AbstractString)
    scenarios = _tracker_scenarios(instance)
    records = Dict{String,Any}[]
    for scenario in scenarios
        append!(records, _tracker_results(scenario["id"]))
    end
    table = DataFrame()
    for col in _SOLUTION_COLUMNS
        table[!, col] = [something(get(r, string(col), missing), missing) for r in records]
    end
    table.solution_plan = _expand_plans.(table.solution_plan)
    sort!(table, [:scen_type, :type_id, :agents])
    return table
end

"""
    _fetch_tracker_solutions(instance)

Return a `DataDeps.DataDep` `fetch_method` closure that downloads the best known solutions for
`instance` from the MAPF tracker API and writes them to `localdir/instance.csv`. This replaces
the `quickDownload` zip endpoint, which the tracker has discontinued in favor of a JSON API (see
[ShortestPathLab/mapf-tracker#35](https://github.com/ShortestPathLab/mapf-tracker/issues/35)).
"""
function _fetch_tracker_solutions(instance::AbstractString)
    return function (_remotepath, localdir)
        table = _download_tracker_solutions(instance)
        path = joinpath(localdir, "$instance.csv")
        CSV.write(path, table)
        return path
    end
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
