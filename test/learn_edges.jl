## Imports

using Base.Threads
using Flux
using Graphs
using InferOpt
using MultiAgentPathFinding
using PythonCall
using ProgressMeter
using SparseArrays
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

mapf = flatland_mapf(pyenv);

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

X = [edges_embedding(mapf) for mapf in instances];
Y = [solution_to_vec(solution, mapf) for (solution, mapf) in zip(solutions, instances)];

function maximizer(θ; mapf)
    g = mapf.graph
    I = [src(ed) for ed in edges(g)]
    J = [dst(ed) for ed in edges(g)]
    edge_weights = sparse(I, J, -θ, nv(g), nv(g))
    solution = independent_shortest_paths(mapf; edge_weights=edge_weights)
    ŷ = solution_to_vec(solution, mapf)
    return ŷ
end

## Initialization

encoder = Chain(Dense(size(X[1], 1), 1), z -> -exp.(z) .- 1., vec)
par = Flux.params(encoder)

model = Perturbed(maximizer; ε=0.02, M=5)
squared_loss(ŷ, y) = sum(abs2, y - ŷ);

Ω = 5
opt = ADAGrad();

k = 1
squared_loss(model(encoder(X[k]); mapf=instances[k]), Y[k]) / nb_instances
Ω * sum(abs, encoder[1].weight)

## Training

nb_epochs = 100
losses = Float64[]
@showprogress "Training -" for epoch in 1:nb_epochs
    l = 0.0
    @showprogress "Epoch $epoch/$nb_epochs -" for k in 1:nb_instances
        gs = gradient(par) do
            l += (
                squared_loss(model(encoder(X[k]); mapf=instances[k]), Y[k]) / nb_instances +
                Ω * sum(abs, encoder[1].weight)
            )
        end
        Flux.update!(opt, par, gs)
    end
    push!(losses, l)
end;

println(lineplot(losses))

encoder[1].weight
