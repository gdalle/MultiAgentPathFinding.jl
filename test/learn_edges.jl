## Imports

using BenchmarkTools
using Flux
using Graphs
using InferOpt
using MultiAgentPathFinding
using PythonCall
using ProgressMeter
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
    width=30,
    height=30,
    number_of_agents=20,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=11,
)
pyenv.reset();

mapf = flatland_mapf(pyenv);

## Data generation

nb_instances = 100

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

solutions_naive = Vector{Solution}(undef, nb_instances);
@showprogress for k in 1:nb_instances
    solutions_naive[k] = cooperative_astar(instances[k])
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

turn_negative(z) = -exp.(z) .- 1.0
repeat_agents(z::AbstractArray) = repeat(z; outer=(1, A))

encoder = Chain(Dense(size(X[1], 1), 1), vec, turn_negative, repeat_agents)
par = Flux.params(encoder)

fenchel_young_loss = FenchelYoungLoss(Perturbed(maximizer; ε=0.1, M=5));

opt = ADAGrad();

k = 1
θ = encoder(X[k])
maximizer(encoder(X[k]); mapf=instances[k])
fenchel_young_loss(encoder(X[k]), Y[k]; mapf=instances[k]) / nb_instances

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

solutions_pred = Vector{Solution}(undef, nb_instances);
@showprogress for k in 1:nb_instances
    mapf = instances[k]
    solution = independent_dijkstra(mapf, -encoder(X[k]))
    feasibility_search!(solution, mapf)
    solutions_pred[k] = solution
end

for k = 1:nb_instances
    mapf = instances[k]
    sol_naive = solutions_naive[k]
    sol_pred = solutions_pred[k]
    sol = solutions[k]
    @info "Solution comparison" flowtime(sol_naive, mapf) flowtime(sol_pred, mapf) flowtime(sol, mapf)
end
