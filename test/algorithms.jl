using Graphs
using MultiAgentPathFinding
using MultiAgentPathFinding: NonExistentPathError
using Random
using SimpleWeightedGraphs
using Test

@testset "Grid" begin
    L = 20
    g = Graphs.grid([L, L])

    A = 20
    departures = collect(1:A)
    arrivals = collect((nv(g) + 1) .- (1:A))

    mapf = MAPF(g, departures, arrivals)

    sol_indep = independent_dijkstra(mapf)
    sol_coop = cooperative_astar(mapf)
    @test !is_feasible(sol_indep, mapf; verbose=false)
    @test is_feasible(sol_coop, mapf, verbose=true)

    f_indep = solution_cost(sol_indep, mapf)
    f_coop = solution_cost(sol_coop, mapf)
    @test f_indep <= f_coop
end

@testset "Infeasible" begin
    g = Graph(2)
    departures = [1]
    arrivals = [2]
    mapf = MAPF(g, departures, arrivals)
    @test_throws NonExistentPathError independent_dijkstra(mapf)
    @test_throws NonExistentPathError cooperative_astar(mapf)

    g = Graph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 3, 4)
    departures = [2, 1]
    arrivals = [4, 2]
    mapf = MAPF(g, departures, arrivals)
    @test_throws NonExistentPathError independent_dijkstra(mapf)
    @test_throws NonExistentPathError cooperative_astar(mapf)
end

@testset "Inconsistent graphs" begin
    @test_throws AssertionError MAPF(Graph(3), [3, 2], [1])
    @test_throws AssertionError MAPF(Graph(3), [3], [4])
    @test_throws AssertionError MAPF(Graph(3), [4], [3])
end
