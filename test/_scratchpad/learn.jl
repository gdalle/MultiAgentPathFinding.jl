## Imports

using BenchmarkTools
using Flux
using GLMakie
using Graphs
using InferOpt
using MultiAgentPathFinding
using ProgressMeter
using PythonCall
using Random
using SparseArrays
using Base.Threads

nthreads()
GLMakie.inline!(true)
Random.seed!(63)

## Test

rail_generators = pyimport("flatland.envs.rail_generators");
line_generators = pyimport("flatland.envs.line_generators");
rail_env = pyimport("flatland.envs.rail_env");

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=10);
line_generator = line_generators.sparse_line_generator();

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

## Data generation

K = 10  # nb of instances

mapfs = Vector{FlatlandMAPF}(undef, K);
@showprogress "Generating instances: " for k in 1:K
    pyenv.reset()
    mapfs[k] = flatland_mapf(pyenv)
end

## Lower bound

solutions_indep = Vector{Solution}(undef, K);
@threads for k in 1:K
    @info "Instance $k solved by thread $(threadid()) (indep)"
    mapf = mapfs[k]
    solution = independent_astar(mapf)
    solutions_indep[k] = solution
end

## Feasible solutions

solutions_coop = Vector{Solution}(undef, K);
@threads for k in 1:K
    @info "Instance $k solved by thread $(threadid()) (coop)"
    mapf = mapfs[k]
    solution = cooperative_astar(mapf)
    solutions_coop[k] = solution
end

solutions_lns2 = Vector{Solution}(undef, K);
@threads for k in 1:K
    @info "Instance $k solved by thread $(threadid()) (LNS2)"
    mapf = mapfs[k]
    solution = independent_dijkstra(mapf)
    feasibility_search!(
        solution,
        mapf;
        conflict_price=10,
        conflict_price_increase=0.01,
        neighborhood_size=5,
        progress=false,
    )
    solutions_lns2[k] = solution
end

## Apply local search

solutions_coop_lns1 = Vector{Solution}(undef, K);
@threads for k in 1:K
    @info "Instance $k solved by thread $(threadid()) (coop + LNS1)"
    mapf = mapfs[k]
    solution = deepcopy(solutions_coop[k])
    large_neighborhood_search!(
        solution,
        mapf;
        steps=1000,
        neighborhood_size=5,
        progress=false,
    )
    solutions_coop_lns1[k] = solution
end

solutions_lns2_lns1 = Vector{Solution}(undef, K);
@threads for k in 1:K
    @info "Instance $k solved by thread $(threadid()) (coop + LNS2)"
    mapf = mapfs[k]
    solution = deepcopy(solutions_lns2[k])
    large_neighborhood_search!(
        solution,
        mapf;
        steps=1000,
        neighborhood_size=5,
        progress=false,
    )
    solutions_lns2_lns1[k] = solution
end

## Eval dataset

mean(flowtime.(solutions_indep, mapfs))
mean(flowtime.(solutions_coop, mapfs))
mean(flowtime.(solutions_lns2, mapfs))
mean(flowtime.(solutions_coop_lns1, mapfs))
mean(flowtime.(solutions_lns2_lns1, mapfs))

solutions_opt = solutions_lns2_lns1;

## Build features

X = Vector{Matrix{Float64}}(undef, K * A)
Y = Vector{Vector{Int}}(undef, K * A)
@threads for k in 1:K
    @info "Instance $k embedded by thread $(threadid())"
    for a in 1:A
        X[(k - 1) * A + a] = all_edges_embedding(a, solutions_indep[k], mapfs[k])
        Y[(k - 1) * A + a] = path_to_vec(solutions_opt[k][a], mapfs[k])
    end
end

F = size(X[1], 1)

## Define pipeline

function maximizer(θ; a, mapf)
    edge_weights = -θ
    path = independent_dijkstra(a, mapf, edge_weights)
    ŷ = path_to_vec(path, mapf)
    return ŷ
end

## Initialization

negative_identity(z) = -z
vector_relu(z) = relu.(z)
dropfirstdim(z) = dropdims(z; dims=1)

initial_encoder = Chain(Dense(F, 1), dropfirstdim, vector_relu, negative_identity)

maximizer(initial_encoder(X[1]); a=1, mapf=mapfs[1])

encoder = deepcopy(initial_encoder)
par = Flux.params(encoder)
fenchel_young_loss = FenchelYoungLoss(PerturbedLogNormal(maximizer; ε=0.1, M=10));
opt = ADAGrad();

## Training

nb_epochs = 30
losses = Float64[]
@showprogress "Training -" for epoch in 1:nb_epochs
    l = 0.0
    @showprogress "Epoch $epoch/$nb_epochs -" for k in 1:K
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

costs_pred_init = zeros(K);
costs_pred_final = zeros(K);
@threads for k in 1:K
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

barplot((1:K), costs_pred_init; width=0.3, label="before learning", color=:red)
barplot!((1:K) .+ 0.3, costs_pred_final; width=0.3, label="after learning", color=:blue)
barplot!((1:K) .+ 0.6, costs_opt; width=0.3, label="optimal", color=:green)
axislegend()
current_figure()
