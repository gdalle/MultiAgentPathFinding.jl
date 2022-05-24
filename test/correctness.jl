using Base.Threads
using MultiAgentPathFinding
using ProgressMeter
using Test

series="street"
instance="Berlin_0_256"

offline = false
if offline
    data_dir = joinpath(@__DIR__, "..", "data")
    map_path = joinpath(data_dir, "$series-map", "$instance.map")
    scenario_path = joinpath(data_dir, "$series-scen", "$instance.map.scen")
    mapf = benchmark_mapf(map_path, scenario_path; buckets=1:30);
else
    mapf = download_benchmark_mapf(series, instance; buckets=1:30);
end

solution_indep = independent_dijkstra(mapf);
solution_coop = cooperative_astar(mapf, 1:nb_agents(mapf));
solution_lns = feasibility_search(mapf);

@testset verbose = true "$series / $instance" begin
    @test !is_feasible(solution_indep, mapf)
    @test is_feasible(solution_coop, mapf)
    @test is_feasible(solution_lns, mapf)
    @test flowtime(solution_indep, mapf) <=
        flowtime(solution_lns, mapf) <=
        flowtime(solution_coop, mapf)
end
