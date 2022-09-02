using Graphs
using MultiAgentPathFinding
using Random
using Test

Random.seed!(63)

# Grid graph where the first and last vertex are departure zones

L = 5
g = SimpleDiGraph(Graphs.grid([L, L]))
Graphs.weights(g)

A = 50
sources = rand(1:nv(g), A);
destinations = rand(1:nv(g), A);
departure_times = rand(1:5, A);

mapf = MAPF(
    g,
    sources,
    destinations;
    departure_times=departure_times,
    stay_at_arrival=true
)

mapf = add_dummy_vertices(mapf)

show_progress = false

solution_indep = independent_dijkstra(mapf);
solution_coop = cooperative_astar(mapf);
solution_os = optimality_search(mapf; show_progress=show_progress);
solution_fs = feasibility_search(mapf; show_progress=show_progress);
solution_ds = double_search(mapf; show_progress=show_progress);

@test !is_feasible(solution_indep, mapf)
@test is_feasible(solution_coop, mapf)
@test is_feasible(solution_os, mapf)
@test is_feasible(solution_fs, mapf)
@test is_feasible(solution_ds, mapf)

f_indep = flowtime(solution_indep, mapf)
f_coop = flowtime(solution_coop, mapf)
f_os = flowtime(solution_os, mapf)
f_fs = flowtime(solution_fs, mapf)
f_ds = flowtime(solution_ds, mapf)

@test f_indep <= f_os <= f_coop
@test f_indep <= f_fs
@test f_indep <= f_ds
