## Imports

using DataFrames
using Flux
# using GLMakie
using InferOpt
using MultiAgentPathFinding
using PythonCall
using ProgressMeter

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=5)
line_generator = line_generators.sparse_line_generator()

pyenv = rail_env.RailEnv(;
    width=30,
    height=30,
    number_of_agents=50,
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

# fig, (A, XY, M) = plot_flatland_graph(mapf);
# fig
# solution = copy(solution_lns);
# framerate = 5
# tmax = maximum(t for path in solution for (t, v) in path)
# @showprogress for t in 1:tmax
#     A[], XY[], M[] = flatland_agent_coords(mapf, solution, t)
#     sleep(1 / framerate)
# end

## Learning

T = 300

X = agents_embedding(mapf)
y = solution_to_vec(solution_indep, mapf, T=T)

function maximizer(θ; mapf)
    permutation = sortperm(θ; rev=true)
    solution = cooperative_astar(mapf, permutation)
    ŷ = solution_to_vec(solution, mapf; T=T)
    return ŷ
end

encoder = Chain(Dense(size(X, 1), 1), vec)
model = Perturbed(maximizer; ε=1.0, M=2)
squared_loss(y, ŷ) = sum(abs2, y - ŷ);
opt = ADAM();

par = Flux.params(encoder)

@showprogress for epoch in 1:100
    gs = gradient(par) do
        squared_loss(model(encoder(X); mapf=mapf), y)
    end
    Flux.update!(opt, par, gs)
end;


encoder[1].weight
