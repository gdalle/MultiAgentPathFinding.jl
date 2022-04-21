## Imports

using Flux
# using GLMakie
using InferOpt
using MultiAgentPathFinding
using PythonCall
using ProgressMeter
using UnicodePlots

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=4)
line_generator = line_generators.sparse_line_generator()

pyenv = rail_env.RailEnv(;
    width=30,
    height=30,
    number_of_agents=20,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=11,
)

# pyenv.reset();
# mapf = flatland_mapf(pyenv);

## Local search

# solution_indep = independent_astar(mapf);
# is_feasible(solution_indep, mapf)
# flowtime(solution_indep, mapf)

# solution_indep_feasible = feasibility_search!(copy(solution_indep), mapf);
# is_feasible(solution_indep_feasible, mapf)
# flowtime(solution_indep_feasible, mapf)

# solution_coop = cooperative_astar(mapf, collect(1:nb_agents(mapf)));
# is_feasible(solution_coop, mapf)
# flowtime(solution_coop, mapf)

# solution_lns = large_neighborhood_search!(
#     copy(solution_indep_feasible), mapf; N=5, steps=1000
# );
# is_feasible(solution_lns, mapf)
# flowtime(solution_lns, mapf)

# tmax = maximum(t for path in solution_lns for (t, v) in path)

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

nb_instances = 2

instances = MAPF[]
@showprogress "Generating instances: " for k in 1:nb_instances
    pyenv.reset()
    mapf = flatland_mapf(pyenv)
    push!(instances, mapf)
end

solutions = Solution[]
@showprogress "Solving instances: " for k in 1:nb_instances
    mapf = instances[k]
    solution = cooperative_astar(mapf, 1:nb_agents(mapf))
    # solution = large_neighborhood_search(mapf; N=10, steps=100, progress=false)
    push!(solutions, solution)
end

T = maximum(max_time(solution) for solution in solutions) * 2
X = [agents_embedding(mapf) for mapf in instances];
Y = [solution_to_vec(solution, mapf; T=T) for (solution, mapf) in zip(solutions, instances)];

function maximizer(θ; mapf)
    permutation = sortperm(θ; rev=true)
    solution = cooperative_astar(mapf, permutation)
    ŷ = solution_to_vec(solution, mapf; T=T)
    return ŷ
end

encoder = Chain(Dense(size(X[1], 1), 1), vec)
model = Perturbed(maximizer; ε=0.1, M=5)
squared_loss(ŷ, y) = sum(abs2, y - ŷ) / T;

opt = ADAGrad();
par = Flux.params(encoder)
losses = Float64[]

k = 1
squared_loss(model(encoder(X[k]); mapf=instances[k]), Y[k])
sum(abs, encoder[1].weight)

for epoch in 1:1000
    @info encoder[1].weight
    l = 0.0
    for k in 1:nb_instances
        gs = gradient(par) do
            l +=
                squared_loss(model(encoder(X[k]); mapf=instances[k]), Y[k]) +
                3*sum(abs, encoder[1].weight)
        end
        Flux.update!(opt, par, gs)
    end
    push!(losses, l)
end;

println(lineplot(losses))
