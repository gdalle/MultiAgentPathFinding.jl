using GridGraphs
using MultiAgentPathFinding
using GLMakie
Makie.inline!(true)

map_path = joinpath("data", "dao-map", "brc101d.map")
scen_path = joinpath("data", "dao-scen", "brc101d.map.scen")

char_matrix = read_benchmark_map(map_path);
scenario = read_benchmark_scenario(scen_path);

# display_benchmark_map(char_matrix)

mapf = benchmark_mapf(map_path, scen_path; bucket=1);
g = mapf.graph
cc = connected_components(g);
bigcc = cc[argmax(length.(cc))];

independent_dijkstra(mapf)
independent_astar(mapf; show_progress=true)
