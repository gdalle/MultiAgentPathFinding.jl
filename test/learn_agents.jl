## Imports

using Base.Threads
using Flux
using Graphs
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
pyenv.reset();

## Data generation

nb_instances = 10

instances = Vector{typeof(flatland_mapf(pyenv))}(undef, nb_instances);
@showprogress "Generating instances: " for k in 1:nb_instances
    pyenv.reset()
    instances[k] = flatland_mapf(pyenv)
end

solutions = Vector{Solution}(undef, nb_instances);
@threads for k in 1:nb_instances
    @info "Instance $k solved by thread $(threadid())"
    solutions[k] = large_neighborhood_search(instances[k]; N=10, steps=100, progress=false)
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

## Initialization

encoder = Chain(Dense(size(X[1], 1), 1), vec)
model = Perturbed(maximizer; ε=0.1, M=10)
squared_loss(ŷ, y) = sum(abs2, y - ŷ) / T;

λ = 30
opt = ADAGrad();
par = Flux.params(encoder)

losses = Float64[]

## Training

for epoch in 1:100
    l = 0.0
    @showprogress "Epoch $epoch/100 - " for k in 1:nb_instances
        gs = gradient(par) do
            l += (
                squared_loss(model(encoder(X[k]); mapf=instances[k]), Y[k]) +
                (λ / nb_instances) * sum(abs, encoder[1].weight)
            )
        end
        Flux.update!(opt, par, gs)
    end
    push!(losses, l)
end;

println(lineplot(losses))

## Evaluation

solutions_naive = Vector{Solution}(undef, nb_instances);
solutions_pred = Vector{Solution}(undef, nb_instances);
for k in 1:nb_instances
    solutions_naive[k] = cooperative_astar(instances[k], 1:nb_agents(instances[k]))
    θ = encoder(X[k])
    permutation = sortperm(θ; rev=true)
    solutions_pred[k] = cooperative_astar(instances[k], permutation)
end

avg_flowtime =
    sum(flowtime(solution, mapf) for (solution, mapf) in zip(solutions, instances)) /
    nb_instances

avg_flowtime_pred =
    sum(flowtime(solution, mapf) for (solution, mapf) in zip(solutions_pred, instances)) /
    nb_instances

avg_flowtime_naive =
    sum(flowtime(solution, mapf) for (solution, mapf) in zip(solutions_naive, instances)) /
    nb_instances
