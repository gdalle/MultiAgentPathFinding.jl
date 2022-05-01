## Imports

using BenchmarkTools
using Graphs
using MultiAgentPathFinding
using PythonCall
using ProgressMeter
using UnicodePlots

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=8)
line_generator = line_generators.sparse_line_generator()

pyenv = rail_env.RailEnv(;
    width=40,
    height=40,
    number_of_agents=100,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=11,
)

pyenv.reset();
mapf = flatland_mapf(pyenv);

## Local search

solution_indep = independent_astar(mapf);
is_feasible(solution_indep, mapf)
flowtime(solution_indep, mapf)

solution_indep2 = independent_dijkstra(mapf);
is_feasible(solution_indep2, mapf)
flowtime(solution_indep2, mapf)

solution_indep_feasible = feasibility_search!(copy(solution_indep), mapf);
is_feasible(solution_indep_feasible, mapf)
flowtime(solution_indep_feasible, mapf)

solution_coop = cooperative_astar(mapf);
is_feasible(solution_coop, mapf)
flowtime(solution_coop, mapf)

solution_coop_soft = cooperative_astar(mapf; soft=true);
is_feasible(solution_coop_soft, mapf)
flowtime(solution_coop_soft, mapf)

solution_lns = large_neighborhood_search!(
    copy(solution_indep_feasible), mapf; N=5, steps=100
);
is_feasible(solution_lns, mapf)
flowtime(solution_lns, mapf)

## (I)LP

# tmax = maximum(t for path in solution_lns for (t, v) in path)

# _, _, solution_lp = solve_lp(mapf, T=tmax+10, integer=false, capacity=true);
# is_feasible(solution_lp, mapf)
# flowtime(solution_lp, mapf)

# _, _, solution_lp_indep = solve_lp(mapf, T=tmax+10, integer=true, capacity=false);
# is_feasible(solution_lp_indep, mapf)
# flowtime(solution_lp_indep, mapf)

# _, _, solution_ilp = solve_lp(mapf, T=tmax+10, integer=true, capacity=true);
# is_feasible(solution_ilp, mapf)
# flowtime(solution_ilp, mapf)

## Animation

# using GLMakie

# fig, (A, XY, M) = plot_flatland_graph(mapf);
# fig
# solution = copy(solution_coop);
# framerate = 5
# tmax = maximum(t for path in solution for (t, v) in path)
# @showprogress for t in 1:tmax
#     A[], XY[], M[] = flatland_agent_coords(mapf, solution, t)
#     sleep(1 / framerate)
# end
