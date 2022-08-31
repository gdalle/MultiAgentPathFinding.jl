using Graphs
using MultiAgentPathFinding
using Random
using Test

Random.seed!(63)

# Grid graph where the first and last vertex are departure zones
L = 30
g = SimpleDiGraph(Graphs.grid([L, L]))
add_edge!(g, 1, 1)
add_edge!(g, nv(g), nv(g))
Graphs.weights(g)

A = 50
sources = fill(1, A);
destinations = fill(nv(g), A);
departure_times = rand(1:10, A);

vertex_conflicts = Vector{Vector{Int}}(undef, nv(g));
for v in vertices(g)
    if 1 < v < nv(g)
        vertex_conflicts[v] = [v]
    else
        vertex_conflicts[v] = Int[]
    end
end

edge_conflicts = Dict{Tuple{Int,Int},Vector{Tuple{Int,Int}}}();
for ed in edges(g)
    u, v = src(ed), dst(ed)
    if u != v
        edge_conflicts[(u, v)] = [(v, u)]
    else
        edge_conflicts[(u, v)] = Tuple{Int,Int}[]
    end
end

mapf = MAPF(
    g,
    sources,
    destinations;
    departure_times=departure_times,
    vertex_conflicts=vertex_conflicts,
    edge_conflicts=edge_conflicts,
)

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
f_ds = flowtime(solution_fs, mapf)

@test f_indep <= f_os <= f_coop
@test f_indep <= f_fs
@test f_indep <= f_ds
