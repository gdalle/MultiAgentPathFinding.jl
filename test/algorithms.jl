using Graphs
using MultiAgentPathFinding
using Test

# Grid graph where the first and last vertex are departure zones
g = SimpleDiGraph(Graphs.grid([30, 30]))
add_edge!(g, 1, 1)
add_edge!(g, nv(g), nv(g))
Graphs.weights(g)

A = 50
sources = rand((1, nv(g)), A);
destinations = rand(2:(nv(g) - 1), A);
starting_times = rand(1:10, A);
vertex_conflicts = vcat([Int[]], [[v] for v in 2:(nv(g) - 1)], [Int[]]);

mapf = MAPF(
    g,
    sources,
    destinations;
    starting_times=starting_times,
    vertex_conflicts=vertex_conflicts,
);

solution_indep = independent_dijkstra(mapf);
solution_coop = cooperative_astar(mapf, 1:nb_agents(mapf));
solution_lns = large_neighborhood_search(mapf);
solution_feasibility_search = feasibility_search(mapf; show_progress=false);

@test !is_feasible(solution_indep, mapf)
@test is_feasible(solution_coop, mapf)
@test is_feasible(solution_lns, mapf)
@test is_feasible(solution_feasibility_search, mapf)

@test flowtime(solution_indep, mapf) <=
    flowtime(solution_lns, mapf) <=
    flowtime(solution_coop, mapf)
@test flowtime(solution_indep, mapf) <= flowtime(solution_feasibility_search, mapf)

x = all_edges_embedding(1, solution_indep, mapf);
@test size(x, 2) == ne(g)
