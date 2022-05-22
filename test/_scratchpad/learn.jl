## Imports

using BenchmarkTools
using Flux
using Graphs
using InferOpt
using MultiAgentPathFinding
using ProgressMeter
using PythonCall
using Random
using SparseArrays
using Statistics
using Base.Threads

nthreads()
GLMakie.inline!(true)
Random.seed!(63)

## Settings

W = 50  # width
H = 50  # height
C = 10  # cities
A = 100  # agents
K = 1  # nb of instances

## Data generation

rail_generators = pyimport("flatland.envs.rail_generators");
line_generators = pyimport("flatland.envs.line_generators");
rail_env = pyimport("flatland.envs.rail_env");

rail_generator = rail_generators.sparse_rail_generator(; max_num_cities=C);
line_generator = line_generators.sparse_line_generator();

pyenv = rail_env.RailEnv(;
    width=W,
    height=H,
    number_of_agents=A,
    rail_generator=rail_generator,
    line_generator=line_generator,
    random_seed=63,
)

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
    solution = cooperative_astar(mapf, 1:A)
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
        conflict_price=1,
        conflict_price_increase=0.01,
        neighborhood_size=A ÷ 10,
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
        solution, mapf; steps=A, neighborhood_size=A ÷ 10, progress=false
    )
    solutions_coop_lns1[k] = solution
end

solutions_lns2_lns1 = Vector{Solution}(undef, K);
@threads for k in 1:K
    @info "Instance $k solved by thread $(threadid()) (coop + LNS2)"
    mapf = mapfs[k]
    solution = deepcopy(solutions_lns2[k])
    large_neighborhood_search!(
        solution, mapf; steps=A, neighborhood_size=A ÷ 10, progress=false
    )
    solutions_lns2_lns1[k] = solution
end

## Eval dataset

mean(flowtime.(solutions_indep, mapfs))
mean(flowtime.(solutions_coop, mapfs))
mean(flowtime.(solutions_coop_lns1, mapfs))
mean(flowtime.(solutions_lns2, mapfs))
mean(flowtime.(solutions_lns2_lns1, mapfs))

solutions_opt = solutions_lns2_lns1;

## Build features

X = Vector{Matrix{Float64}}(undef, K * A);
Y = Vector{Vector{Int}}(undef, K * A);
@threads for k in 1:K
    @info "Instance $k embedded by thread $(threadid())"
    mapf = mapfs[k]
    for a in 1:A
        embedding = all_edges_embedding(a, solutions_indep[k], mapf)
        m = mean(embedding; dims=2)
        s = std(embedding; dims=2)
        s[iszero.(s)] .= 1.0
        embedding .-= m
        embedding ./= s
        X[(k - 1) * A + a] = embedding
        Y[(k - 1) * A + a] = path_to_vec(solutions_opt[k][a], mapf)
    end
end

F = size(X[1], 1)

## Define pipeline

function maximizer(θ; a, mapf)
    edge_weights_vec = -θ
    path = agent_dijkstra(a, mapf, edge_weights_vec)
    ŷ = path_to_vec(path, mapf)
    return ŷ
end

## Initialization

make_positive(z) = celu.(z) .+ 1.01;
switch_sign(z) = -z;
dropfirstdim(z) = dropdims(z; dims=1);

perturbed = PerturbedLogNormal(maximizer; ε=1, M=5)
fenchel_young_loss = FenchelYoungLoss(perturbed)

initial_encoder = Chain(Dense(F, 1), dropfirstdim, make_positive, switch_sign)
encoder = deepcopy(initial_encoder)

par = Flux.params(encoder);
opt = ADAM()

diversification = (
    sum(!iszero, perturbed(-mapfs[1].edge_weights_vec; a=1, mapf=mapfs[1])) /
    sum(!iszero, maximizer(-mapfs[1].edge_weights_vec; a=1, mapf=mapfs[1]))
)

## Training

nb_epochs = 50
losses, distances = Float64[], Float64[]
for epoch in 1:nb_epochs
    l = 0.0
    d = 0.0
    @showprogress "Epoch $epoch" for k in 1:K
        mapf = mapfs[k]
        for a in 1:A
            x, y = X[(k - 1) * A + a], Y[(k - 1) * A + a]
            ŷ = maximizer(encoder(x); a=a, mapf=mapf)
            d += sum(abs, ŷ - y)
            gs = gradient(par) do
                l += fenchel_young_loss(encoder(x), y; a=a, mapf=mapf)
            end
            Flux.update!(opt, par, gs)
        end
    end
    @info "After epoch $epoch: loss $l - distance $d"
    push!(losses, l)
    push!(distances, d)
    epoch > 1 && losses[end] ≈ losses[end - 1] && break
end;

losses
distances

## Eval

costs_opt = [flowtime(solution, mapf) for (solution, mapf) in zip(solutions_opt, mapfs)];
costs_indep = [flowtime(solution, mapf) for (solution, mapf) in zip(solutions_indep, mapfs)];

costs_pred_init = zeros(K);
costs_pred_final = zeros(K);

for k in 1:K  # Error
    mapf = mapfs[k]
    edge_weights_mat_init = reduce(hcat, -initial_encoder(X[(k - 1) * A + a]) for a = 1:A)
    edge_weights_mat_final = reduce(hcat, -encoder(X[(k - 1) * A + a]) for a = 1:A)
    solution_pred_init = cooperative_astar(mapf, 1:A, edge_weights_mat_init)
    solution_pred_final = cooperative_astar(mapf, 1:A, edge_weights_mat_final)
    costs_pred_init[k] += flowtime(solution_pred_init, mapf)
    costs_pred_final[k] += flowtime(solution_pred_final, mapf)
    @info "Instance $k solved by thread $(threadid())"
end

costs_pred_init
costs_pred_final
costs_opt
