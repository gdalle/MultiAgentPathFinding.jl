## Imports

@time_imports using BenchmarkTools
@time_imports using Flux
@time_imports using GLMakie
@time_imports using Graphs
@time_imports using InferOpt
@time_imports using MultiAgentPathFinding
@time_imports using ProgressMeter
@time_imports using PythonCall
@time_imports using SparseArrays
@time_imports using Base.Threads

nthreads()
GLMakie.inline!(true)

## Test

rail_generators = pyimport("flatland.envs.rail_generators")
line_generators = pyimport("flatland.envs.line_generators")
rail_env = pyimport("flatland.envs.rail_env")

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=3)
line_generator = line_generators.sparse_line_generator()

A = 50

pyenv = rail_env.RailEnv(;
    width=35,
    height=35,
    number_of_agents=A,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=11,
)
pyenv.reset();

mapf = flatland_mapf(pyenv);

## Data generation

nb_instances = 10

all_instances = Vector{typeof(flatland_mapf(pyenv))}(undef, nb_instances);
@showprogress "Generating instances: " for k in 1:nb_instances
    pyenv.reset()
    all_instances[k] = flatland_mapf(pyenv)
end

solutions = Vector{Solution}(undef, nb_instances);
@threads for k in 1:nb_instances
    @info "Instance $k solved by thread $(threadid())"
    solutions[k] = independent_dijkstra(all_instances[k])
    feasibility_search!(solutions[k], all_instances[k]; neighborhood_size=5, progress=false)
end

X = Vector{Array{Float64,3}}(undef, nb_instances)
@threads for k in 1:nb_instances
    @info "Instance $k embedded by thread $(threadid())"
    X[k] = edges_agents_embedding(all_instances[k])
end
nb_features = size(X[1], 1)

Y = [solution_to_mat(solution, mapf) for (solution, mapf) in zip(solutions, all_instances)];

function maximizer(θ; mapf)
    edge_weights = -θ
    solution = independent_dijkstra(mapf, edge_weights)
    ŷ = solution_to_mat(solution, mapf)
    return ŷ
end

## Initialization

negative_identity(z) = -z
vector_relu(z) = relu.(z)
dropfirstdim(z) = dropdims(z; dims=1)

initial_encoder = Chain(
    Dense(nb_features, 1),
    dropfirstdim,
    vector_relu,
    negative_identity,
)

encoder = deepcopy(initial_encoder)
par = Flux.params(encoder)
fenchel_young_loss = FenchelYoungLoss(PerturbedLogNormal(maximizer; ε=0.1, M=10));
opt = ADAGrad();

## Training

nb_epochs = 30
losses = Float64[]
@showprogress "Training -" for epoch in 1:nb_epochs
    l = 0.0
    @showprogress "Epoch $epoch/$nb_epochs -" for k in 1:nb_instances
        gs = gradient(par) do
            l += fenchel_young_loss(encoder(X[k]), Y[k]; mapf=all_instances[k])
        end
        Flux.update!(opt, par, gs)
    end
    @info "Loss $l"
    push!(losses, l)
end;

lines(log.(losses))

## Eval

costs_opt = [flowtime(solution, mapf) for (solution, mapf) in zip(solutions, all_instances)];

nb_trials = 5

costs_pred_init = zeros(nb_instances);
costs_pred_final = zeros(nb_instances);
@threads for k in 1:nb_instances
    mapf = all_instances[k]
    for _ in 1:nb_trials
        solution_pred_init = independent_dijkstra(mapf, -encoder(X[k]))
        solution_pred_final = independent_dijkstra(mapf, -initial_encoder(X[k]))
        feasibility_search!(solution_pred_init, mapf; neighborhood_size=5, progress=false)
        feasibility_search!(solution_pred_final, mapf; neighborhood_size=5, progress=false)
        costs_pred_init[k] += flowtime(solution_pred_init, mapf) / nb_trials
        costs_pred_final[k] += flowtime(solution_pred_final, mapf) / nb_trials
    end
    @info "Instance $k solved by thread $(threadid())"
end

barplot((1:nb_instances), costs_pred_init; width=0.3, label="before learning", color=:red)
barplot!(
    (1:nb_instances) .+ 0.3,
    costs_pred_final;
    width=0.3,
    label="after learning",
    color=:blue,
)
barplot!((1:nb_instances) .+ 0.6, costs_opt; width=0.3, label="optimal", color=:green)
axislegend()
current_figure()
