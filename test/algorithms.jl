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

mapf1 = MAPF(
    g, sources, destinations; departure_times=departure_times, stay_at_arrival=true
)
mapf2 = add_dummy_vertices(mapf1)

show_progress = true

@testset verbose = true "Infeasible" begin
    sol1_indep = independent_dijkstra(mapf1)
    sol1_coop = cooperative_astar(mapf1)
    sol1_os = optimality_search(mapf1; show_progress=show_progress)
    sol1_fs = feasibility_search(mapf1; show_progress=show_progress)
    sol1_ds = double_search(mapf1; show_progress=show_progress)
    @test !is_feasible(sol1_indep, mapf1)
    @test !is_feasible(sol1_coop, mapf1)
    @test !is_feasible(sol1_os, mapf1)
    @test !is_feasible(sol1_fs, mapf1)
    @test !is_feasible(sol1_ds, mapf1)
end

@testset verbose = true "Feasible" begin
    sol2_indep = independent_dijkstra(mapf2)
    sol2_coop = cooperative_astar(mapf2)
    sol2_os = optimality_search(mapf2; show_progress=show_progress)
    sol2_fs = feasibility_search(mapf2; show_progress=show_progress)
    sol2_ds = double_search(mapf2; show_progress=show_progress)
    @test !is_feasible(sol2_indep, mapf2)
    @test is_feasible(sol2_coop, mapf2)
    @test is_feasible(sol2_os, mapf2)
    @test is_feasible(sol2_fs, mapf2)
    @test is_feasible(sol2_ds, mapf2)
    f2_indep = flowtime(sol2_indep, mapf2)
    f2_coop = flowtime(sol2_coop, mapf2)
    f2_os = flowtime(sol2_os, mapf2)
    f2_fs = flowtime(sol2_fs, mapf2)
    f2_ds = flowtime(sol2_ds, mapf2)
    @test f2_indep <= f2_os <= f2_coop
    @test f2_indep <= f2_fs
    @test f2_indep <= f2_ds
end
