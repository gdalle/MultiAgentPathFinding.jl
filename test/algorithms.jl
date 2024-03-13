using Graphs
using MultiAgentPathFinding
using Random
using Test

Random.seed!(63)

L = 10
g = Graphs.grid([L, L])

A = 10
departures = 1:A;
arrivals = (nv(g) + 1) .- (1:A);

mapf = MAPF(g; departures, arrivals);

show_progress = true

sol_indep = independent_dijkstra(mapf; show_progress);
sol_coop = cooperative_astar(mapf; show_progress);
sol_os, stats_os = optimality_search(mapf; show_progress);
sol_fs, stats_fs = feasibility_search(mapf; show_progress);
sol_ds, stats_ds = double_search(mapf; show_progress);

@test !is_feasible(sol_indep, mapf; verbose=false)
@test is_feasible(sol_coop, mapf, verbose=true)
@test is_feasible(sol_os, mapf, verbose=true)
@test is_feasible(sol_fs, mapf, verbose=true)
@test is_feasible(sol_ds, mapf, verbose=true)

f_indep = solution_cost(sol_indep, mapf)
f_coop = solution_cost(sol_coop, mapf)
f_fs = solution_cost(sol_fs, mapf)
f_os = solution_cost(sol_os, mapf)
f_ds = solution_cost(sol_ds, mapf)

stats_os
stats_fs
stats_ds

@test f_indep <= f_os <= f_coop
@test f_indep <= f_ds <= f_fs
