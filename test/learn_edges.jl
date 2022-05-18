## Imports

using BenchmarkTools
using Flux
using Graphs
using InferOpt
using MultiAgentPathFinding
using ProgressMeter
using PythonCall
using SparseArrays
using UnicodePlots
using Base.Threads;
nthreads();

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=3)
line_generator = line_generators.sparse_line_generator()

pyenv = rail_env.RailEnv(;
    width=35,
    height=35,
    number_of_agents=50,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=11,
)
pyenv.reset();

mapf = flatland_mapf(pyenv);

## Data generation

nb_instances = 1

instances = Vector{typeof(flatland_mapf(pyenv))}(undef, nb_instances);
@showprogress "Generating instances: " for k in 1:nb_instances
    pyenv.reset()
    instances[k] = flatland_mapf(pyenv)
end

solutions = Vector{Solution}(undef, nb_instances);
@threads for k in 1:nb_instances
    @info "Instance $k solved by thread $(threadid())"
    solutions[k] = large_neighborhood_search(
        instances[k]; neighborhood_size=5, steps=100, progress=false
    )
end

A = nb_agents(instances[1])
X = [edges_embedding(mapf) for mapf in instances];
Y = [solution_to_mat(solution, mapf) for (solution, mapf) in zip(solutions, instances)];

function maximizer(θ; mapf)
    edge_weights = -θ
    solution = independent_dijkstra(mapf, edge_weights)
    ŷ = solution_to_mat(solution, mapf)
    return ŷ
end

## Initialization

turn_negative(z) = -exp.(z) .- 1
repeat_agents(z::AbstractArray) = repeat(z; outer=(1, A))

initial_encoder = Chain(Dense(size(X[1], 1), 1), vec, turn_negative, repeat_agents)
encoder = deepcopy(initial_encoder)
par = Flux.params(encoder)

fenchel_young_loss = FenchelYoungLoss(Perturbed(maximizer; ε=0.2, M=5));

opt = ADAGrad();

## Training

nb_epochs = 100
losses = Float64[]
@showprogress "Training -" for epoch in 1:nb_epochs
    l = 0.0
    @showprogress "Epoch $epoch/$nb_epochs -" for k in 1:nb_instances
        gs = gradient(par) do
            l += fenchel_young_loss(encoder(X[k]), Y[k]; mapf=instances[k])
        end
        Flux.update!(opt, par, gs)
    end
    push!(losses, l / nb_instances)
end;

println(lineplot(losses))

encoder[1].weight

## Eval

costs_opt = [flowtime(solution, mapf) for (solution, mapf) in zip(solutions, instances)]

nb_trials = 5

costs_pred_init = zeros(nb_instances);
costs_pred_final = zeros(nb_instances);
@threads for k in 1:nb_instances
    mapf = instances[k]
    for _ = 1:nb_trials
        solution_pred_init = independent_dijkstra(mapf, -encoder(X[k]))
        solution_pred_final = independent_dijkstra(mapf, -initial_encoder(X[k]))
        feasibility_search!(solution_pred_init, mapf; neighborhood_size=5, progress=false)
        feasibility_search!(solution_pred_final, mapf; neighborhood_size=5, progress=false)
        costs_pred_init[k] += flowtime(solution_pred_init, mapf) / nb_trials
        costs_pred_final[k] += flowtime(solution_pred_final, mapf) / nb_trials
    end
    @info "Instance $k solved by thread $(threadid())"
end

barplot((1:nb_instances), costs_opt, bar_width=0.3, label="optimal")
barplot((1:nb_instances) .+ 0.3, costs_pred_final, bar_width=0.3, label="after_learning")
barplot((1:nb_instances) .+ 0.6, costs_pred_init, bar_width=0.3, label="before_learning")
