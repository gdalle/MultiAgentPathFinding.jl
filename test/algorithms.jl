using Graphs
using JET
using MultiAgentPathFinding
using Random
using Test

Random.seed!(63)

show_progress = get(ENV, "CI", "false") == "false"

@testset "Grid" begin
    L = 20
    g = Graphs.grid([L, L])

    A = 20
    departures = 1:A
    arrivals = (nv(g) + 1) .- (1:A)

    mapf = MAPF(g; departures, arrivals)

    sol_indep = independent_dijkstra(mapf; show_progress)
    sol_coop = cooperative_astar(mapf; show_progress)
    sol_os, stats_os = optimality_search(mapf; show_progress)
    sol_fs, stats_fs = feasibility_search(mapf; show_progress)
    sol_ds, stats_ds = double_search(mapf; show_progress)

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

    @test f_indep <= f_os <= f_coop
    @test f_indep <= f_ds <= f_fs
end

@testset "Disconnected graphs" begin
    g = Graph(2)
    departures = [1]
    arrivals = [2]
    mapf = MAPF(g; departures, arrivals)
    sol_indep = independent_dijkstra(mapf)
    sol_coop = cooperative_astar(mapf)
    @test !is_feasible(sol_indep, mapf)
    @test !is_feasible(sol_coop, mapf)

    g = Graph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 3, 4)
    departures = [2, 1]
    arrivals = [4, 2]
    mapf = MAPF(g; departures, arrivals)
    sol_indep = independent_dijkstra(mapf)
    sol_coop = cooperative_astar(mapf)
    @test !is_feasible(sol_indep, mapf)
    @test !is_feasible(sol_coop, mapf)
    @test isempty(sol_coop.timed_paths[1].path)

    g = Graph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 3, 4)
    departures = [2, 1]
    arrivals = [4, 2]
    mapf = MAPF(g; departures, arrivals)
    sol_indep = independent_dijkstra(mapf)
    sol_coop = cooperative_astar(mapf)
    @test !is_feasible(sol_indep, mapf)
    @test !is_feasible(sol_coop, mapf)
    @test isempty(sol_coop.timed_paths[1].path)
end

@testset "Inconsistent graphs" begin
    @test_throws AssertionError MAPF(Graph(3); departures=[3, 2], arrivals=[1])
    @test_throws AssertionError MAPF(Graph(3); departures=[3], arrivals=[4])
    @test_throws AssertionError MAPF(Graph(3); departures=[4], arrivals=[3])
end
