using MultiAgentPathFinding
using MultiAgentPathFinding:
    read_benchmark_map,
    read_benchmark_scenario,
    parse_benchmark_map,
    parse_benchmark_scenario,
    benchmark_cell_color,
    map_from_scenario,
    scenarios_from_map
using Graphs
using ProgressMeter
using Test

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
