using Base.Threads
using MultiAgentPathFinding
using ProgressMeter
using Test

series = "maze"
instance = "maze512-1-0"

map_path = joinpath(@__DIR__, "..", "data", "$series-map", "$instance.map")
scenario_path = joinpath(@__DIR__, "..", "data", "$series-scen", "$instance.map.scen")

mapf = benchmark_mapf(map_path, scenario_path; buckets=1:40);

solution_indep = independent_dijkstra(mapf);
solution_coop = cooperative_astar(mapf, 1:nb_agents(mapf));
solution_lns = feasibility_search(mapf);

@test is_solvable(mapf)
@test !is_feasible(solution_indep, mapf)
@test is_feasible(solution_coop, mapf)
@test is_feasible(solution_lns, mapf)
@test flowtime(solution_indep, mapf) <
    flowtime(solution_lns, mapf) <=
    flowtime(solution_coop, mapf)

## Test all maps & scenarios

testall = false

if testall
    @threads for map_folder in collect(filter(endswith("-map"), readdir("data")))
        scenario_folder = replace(map_folder, "-map" => "-scen")
        for map_file in readdir(joinpath("data", map_folder))
            scenario_file = replace(map_file, ".map" => ".map.scen")
            map_path = joinpath("data", map_folder, map_file)
            scenario_path = joinpath("data", scenario_folder, scenario_file)
            mapf = benchmark_mapf(map_path, scenario_path; buckets=1:typemax(Int));
        end
    end
end
