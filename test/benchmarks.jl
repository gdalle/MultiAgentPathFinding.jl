using MultiAgentPathFinding
using MultiAgentPathFinding:
    read_benchmark_map,
    read_benchmark_scenario,
    parse_benchmark_map,
    parse_benchmark_scenario,
    benchmark_cell_color,
    map_from_scenario,
    scenarios_from_map,
    check_benchmark_scenario
using Graphs
using ProgressMeter
using Test

map_name = "Berlin_1_256.map"
scenario_name = "Berlin_1_256-even-1.scen"

map_matrix = read_benchmark_map(map_name);
# benchmark_cell_color.(map_matrix)
g, coord_to_vertex = parse_benchmark_map(map_matrix)
scenario = read_benchmark_scenario(scenario_name, map_name);
departures, arrivals = parse_benchmark_scenario(scenario, coord_to_vertex);
mapf = read_benchmark(map_name, scenario_name)

@test size(map_matrix) == (256, 256)
@test nb_agents(mapf) == 950
@test nv(mapf.g) == 47540

small_mapf = select_agents(mapf, 1:100)
sol = cooperative_astar(small_mapf; show_progress=false)
@test is_feasible(sol, small_mapf)

all_scenarios_coherent = true
@showprogress for map_name in list_map_names()
    map_matrix = read_benchmark_map(map_name)
    g, coord_to_vertex = parse_benchmark_map(map_matrix)
    for scenario_name in scenarios_from_map(map_name)
        scenario = read_benchmark_scenario(scenario_name, map_name)
        departures, arrivals = parse_benchmark_scenario(scenario, coord_to_vertex)
        if !check_benchmark_scenario(scenario, g, coord_to_vertex)
            global all_scenarios_coherent = false
        end
    end
end
@test all_scenarios_coherent
