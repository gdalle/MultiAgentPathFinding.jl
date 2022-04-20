using MultiAgentPathFinding

map_path = joinpath("data", "wc3maps512-map", "divideandconquer.map")
scen_path = joinpath("data", "wc3maps512-scen", "divideandconquer.map.scen")

map_matrix = read_map(map_path);
scenario = read_scenario(scen_path);

display_map(map_matrix)
g = GridGraph(map_matrix)

ne(g)

agent = scenario[200, :]
(is, js) = size(g, 1) - agent.start_y + 1, agent.start_x
(id, jd) = size(g, 1) - agent.goal_y + 1, agent.goal_x
path = shortest_path_grid(g, (is, js), (id, jd))

display_map(map_matrix; path=path)
