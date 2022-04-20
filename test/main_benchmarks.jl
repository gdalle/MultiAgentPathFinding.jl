using MultiAgentPathFinding

map_path = joinpath("data", "room-map", "64room_000.map")
scen_path = joinpath("data", "room-scen", "64room_000.map.scen")

map_matrix = read_map(map_path);
scenario = read_scenario(scen_path);

display_map(map_matrix)

g = GridGraph(map_matrix)

agent = scenario[rand(1:size(scenario, 1)), :]
(is, js) = agent.start_i, agent.start_j
(id, jd) = agent.goal_i, agent.goal_j
path = shortest_path_grid(g, (is, js), (id, jd))

display_map(map_matrix; path=path)

mapf = benchmark_mapf(map_matrix, scenario; bucket=3)

cooperative_astar(mapf)
