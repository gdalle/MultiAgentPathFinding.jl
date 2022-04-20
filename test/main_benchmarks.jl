using MultiAgentPathFinding

map_path = joinpath("data", "wc3maps512-map", "divideandconquer.map")
scen_path = joinpath("data", "wc3maps512-scen", "divideandconquer.map.scen")

map_matrix = read_map(map_path);
scenario = read_scenario(scen_path);

display_map(map_matrix)
