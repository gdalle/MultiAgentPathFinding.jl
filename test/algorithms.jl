using Graphs
using MultiAgentPathFinding
using Random
using Test

Random.seed!(63)

# Grid graph where the first and last vertex are departure zones

L = 5
g = SimpleDiGraph(Graphs.grid([L, L]))
for v in vertices(g)
    add_edge!(g, v, v)
end

A = 20
departures = rand(1:nv(g), A);
arrivals = rand(1:nv(g), A);

mapf = MAPF(g, departures, arrivals; stay_at_arrival=false);

mapf = MultiAgentPathFinding.add_departure_waiting_vertices(mapf)

show_progress = true

sol_indep = independent_dijkstra(mapf);
sol_coop = cooperative_astar(mapf, 1:nb_agents(mapf));
sol_os = optimality_search(mapf; show_progress=show_progress);
sol_fs = feasibility_search(mapf; show_progress=show_progress);
sol_ds = double_search(mapf; show_progress=show_progress);

@test !is_feasible(sol_indep, mapf)
@test is_feasible(sol_coop, mapf, verbose=true)
@test is_feasible(sol_os, mapf)
@test is_feasible(sol_fs, mapf)
@test is_feasible(sol_ds, mapf)

f_indep = flowtime(sol_indep, mapf)
f_coop = flowtime(sol_coop, mapf)
f_os = flowtime(sol_os, mapf)
f_fs = flowtime(sol_fs, mapf)
f_ds = flowtime(sol_ds, mapf)

@test f_indep <= f_os <= f_coop
@test f_indep <= f_fs
@test f_indep <= f_ds
