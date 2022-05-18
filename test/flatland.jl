using MultiAgentPathFinding
using PythonCall
using Test

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=10)
line_generator = line_generators.sparse_line_generator()

pyenv = rail_env.RailEnv(;
    width=50,
    height=50,
    number_of_agents=100,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=63,
)

pyenv.reset();
mapf = flatland_mapf(pyenv);

solution_indep = independent_astar(mapf);
solution_indep2 = independent_dijkstra(mapf);
solution_coop = cooperative_astar(mapf);
solution_lns2 = feasibility_search(
    mapf; neighborhood_size=5, conflict_price=1, conflict_price_increase=1e-2
);

@test !is_feasible(solution_indep, mapf)
@test !is_feasible(solution_indep2, mapf)
@test is_feasible(solution_coop, mapf)
@test is_feasible(solution_lns2, mapf)
@test flowtime(solution_indep, mapf) ==
    flowtime(solution_indep2, mapf) <=
    flowtime(solution_lns2, mapf) <=
    flowtime(solution_coop, mapf)
