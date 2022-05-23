using MultiAgentPathFinding
using Test

series = "maze"
instance = "maze512-1-0"

map_path = joinpath(@__DIR__, "..", "data", "$series-map", "$instance.map")
scenario_path = joinpath(@__DIR__, "..", "data", "$series-scen", "$instance.map.scen")

mapf = benchmark_mapf(map_path, scenario_path; buckets=1:25);

solution_indep = independent_dijkstra(mapf);
solution_coop = cooperative_astar(mapf, 1:nb_agents(mapf));

@test is_feasible(mapf)
@test !is_feasible(solution_indep, mapf)
@test is_feasible(solution_coop, mapf)
@test flowtime(solution_indep, mapf) < flowtime(solution_coop, mapf)
