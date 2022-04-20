## Imports

using MultiAgentPathFinding
using PythonCall

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=3)
line_generator = line_generators.sparse_line_generator()

pyenv = rail_env.RailEnv(;
    width=30,
    height=30,
    number_of_agents=5,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=11,
)
pyenv.reset();

mapf = generate_mapf(pyenv);

## Local search

solution_indep = independent_astar(mapf);
is_feasible(solution_indep, mapf)
flowtime(solution_indep, mapf)

solution_indep_feasible = feasibility_search!(copy(solution_indep), mapf);
is_feasible(solution_indep_feasible, mapf)
flowtime(solution_indep_feasible, mapf)

solution_coop = cooperative_astar(mapf, collect(1:nb_agents(mapf)));
is_feasible(solution_coop, mapf)
flowtime(solution_coop, mapf)

solution_lns = large_neighborhood_search!(
    copy(solution_indep_feasible), mapf; N=5, steps=1000
);
is_feasible(solution_lns, mapf)
flowtime(solution_lns, mapf)

tmax = maximum(t for path in solution_lns for (t, v) in path)

## (I)LP

_, _, solution_lp = solve_lp(mapf, T=tmax+10, integer=false, capacity=true);
is_feasible(solution_lp, mapf)
flowtime(solution_lp, mapf)

_, _, solution_lp_indep = solve_lp(mapf, T=tmax+10, integer=true, capacity=false);
is_feasible(solution_lp_indep, mapf)
flowtime(solution_lp_indep, mapf)

_, _, solution_ilp = solve_lp(mapf, T=tmax+10, integer=true, capacity=true);
is_feasible(solution_ilp, mapf)
flowtime(solution_ilp, mapf)

## Animation

# using GLMakie

# fig, (A, XY, M) = plot_network(mapf.graph);
# fig
# solution = copy(solution_lns1);
# tmax = maximum(t for path in solution for (t, v) in path)
# framerate = 5
# @showprogress for t in 1:tmax
#     A[], XY[], M[] = agent_coords(mapf.graph, solution, t)
#     sleep(1 / framerate)
# end
