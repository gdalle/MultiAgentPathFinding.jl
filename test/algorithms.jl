using Graphs
using MultiAgentPathFinding
using Random
using StatsBase
using Test

Random.seed!(63)

L = 20
g = SimpleDiGraph(Graphs.grid([L, L]))

A = 100
departures = rand(1:nv(g), A);
arrivals = rand(1:nv(g), A);

mapf = MAPF(g, departures, arrivals; stay_at_arrival=false);
mapf = MultiAgentPathFinding.add_departure_waiting_vertices(mapf);

show_progress = false

sol_indep = independent_dijkstra(mapf; show_progress=show_progress);
sol_coop = repeated_cooperative_astar(mapf; show_progress=show_progress);
sol_os = optimality_search(mapf; show_progress=show_progress);
sol_fs = feasibility_search(mapf; show_progress=show_progress);
sol_ds = double_search(mapf; show_progress=show_progress);

@test !is_feasible(sol_indep, mapf; verbose=false)
@test is_feasible(sol_coop, mapf, verbose=true)
@test is_feasible(sol_os, mapf, verbose=true)
@test is_feasible(sol_fs, mapf, verbose=true)
@test is_feasible(sol_ds, mapf, verbose=true)

f_indep = flowtime(sol_indep, mapf)
f_coop = flowtime(sol_coop, mapf)
f_os = flowtime(sol_os, mapf)
f_fs = flowtime(sol_fs, mapf)
f_ds = flowtime(sol_ds, mapf)

@test f_indep <= f_os <= f_coop
@test f_indep <= f_fs
@test f_indep <= f_ds
