using MultiAgentPathFinding
using MultiAgentPathFinding:
    read_benchmark_map,
    read_benchmark_scenario,
    parse_benchmark_map,
    parse_benchmark_scenario,
    benchmark_cell_color,
    map_from_scenario,
    scenarios_from_map
using MultiAgentPathFinding: cooperative_astar!, optimality_search!, feasibility_search!
using Graphs
using ProgressMeter
using Test

show_progress = get(ENV, "CI", "false") == "false"

## Test one scenario

map_name = "Berlin_1_256.map"
scenario_name = "Berlin_1_256-even-1.scen"

map_matrix = read_benchmark_map(map_name);
g, coord_to_vertex = parse_benchmark_map(map_matrix)
scenario = read_benchmark_scenario(scenario_name, map_name);
departures, arrivals = parse_benchmark_scenario(scenario, coord_to_vertex);
mapf = read_benchmark(map_name, scenario_name; check=true)

@test size(map_matrix) == (256, 256)
@test nv(g) == 47540
@test nb_agents(mapf) == 950
A = nb_agents(mapf)

spt_by_arr = dijkstra_by_arrival(mapf; show_progress);
sol_indep = independent_dijkstra(mapf; spt_by_arr, show_progress);

sol_coop = Solution()
stats_coop = cooperative_astar!(sol_coop, mapf, 1:A, spt_by_arr; show_progress)

sol_os = deepcopy(sol_coop)
stats_os = optimality_search!(
    sol_os, mapf, spt_by_arr; show_progress, optimality_timeout=10, neighborhood_size=10
);

sol_fs = deepcopy(sol_indep)
stats_fs = feasibility_search!(
    sol_fs,
    mapf,
    spt_by_arr;
    show_progress,
    feasibility_timeout=10,
    neighborhood_size=10,
    conflict_price=0.1,
    conflict_price_increase=0.01,
);

@test !is_feasible(sol_indep, mapf)
@test is_feasible(sol_coop, mapf)
@test is_feasible(sol_os, mapf)
@test_broken is_feasible(sol_fs, mapf)

f_indep = solution_cost(sol_indep, mapf)
f_coop = solution_cost(sol_coop, mapf)
f_fs = solution_cost(sol_fs, mapf)
f_os = solution_cost(sol_os, mapf)

@test f_indep <= f_os <= f_coop
@test f_indep <= f_fs

## Test all scenarios

list1 = sort([
    (map_name, scenario_name) for map_name in list_map_names() for
    scenario_name in scenarios_from_map(map_name)
])
list2 = sort([
    (map_from_scenario(scenario_name), scenario_name) for
    scenario_name in list_scenario_names()
])
@test list1 == list2

@showprogress "Reading benchmarks" for map_name in list_map_names()
    for scenario_name in scenarios_from_map(map_name)
        read_benchmark(map_name, scenario_name)
    end
end
