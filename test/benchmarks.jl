
using MultiAgentPathFinding
using Graphs
using Test

map_name = "Berlin_1_256.map"
scenario_name = "Berlin_1_256-even-1.scen"

map_matrix = read_benchmark_map(map_name)
# cell_color.(map_matrix)
g, coord_to_vertex = parse_benchmark_map(map_matrix)

scenario = read_benchmark_scenario(scenario_name, map_name)

mapf = read_benchmark(map_name, scenario_name)
@test nb_agents(mapf) == 950
@test nv(mapf.g) == 47540

small_mapf = select_agents(mapf, 1:100)
sol = cooperative_astar(small_mapf; show_progress=false)
@test is_feasible(sol, small_mapf)
