using Graphs
using LinearAlgebra
using MultiAgentPathFinding
using MultiAgentPathFinding:
    NoConflictFreePathError,
    NoPathError,
    Reservation,
    dijkstra,
    temporal_astar,
    reconstruct_path
using Random
using SimpleWeightedGraphs
using SparseArrays
using StableRNGs
using Test

@testset "Shortest paths" begin
    @testset "Dijkstra" begin
        for k in 1:10
            A = sprand(StableRNG(k), 100, 100, k / 20)
            g = SimpleWeightedGraph(Symmetric(A))
            dep, arr = 1, nv(g)

            result = dijkstra(g, dep)
            result_ref = Graphs.dijkstra_shortest_paths(g, dep)
            @test result.dists == result_ref.dists
            @test result.parents == result_ref.parents
            path = reconstruct_path(result, dep, arr)
            path_ref = Graphs.path_from_parents(arr, result_ref.parents)
            @test path == path_ref
        end
    end

    @testset "A*" begin
        for k in 1:10
            A = sprand(StableRNG(k), 100, 100, k / 20)
            g = SimpleWeightedGraph(Symmetric(A))
            dep, arr = 1, nv(g)

            heuristic = zeros(nv(g))
            reservation = Reservation()
            path = temporal_astar(g, dep, arr; reservation, heuristic)
            result_ref = Graphs.a_star(g, dep, arr)
            path_ref = vcat(Graphs.src.(result_ref), arr)
            @test path == path_ref
        end
    end
end

@testset "Infeasible" begin
    @testset "Disconnected" begin
        g = Graph(2)
        departures = [1]
        arrivals = [2]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoPathError independent_dijkstra(mapf)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
        @test_throws NoConflictFreePathError cooperative_astar(mapf; conflict_price=1)

        g = Graph(4)
        add_edge!(g, 1, 2)
        add_edge!(g, 3, 4)
        departures = [2, 1]
        arrivals = [4, 2]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoPathError independent_dijkstra(mapf)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
        @test_throws NoConflictFreePathError cooperative_astar(mapf; conflict_price=1)
    end

    @testset "Vertex conflict" begin
        g = path_graph(4)
        departures = [1, 3]
        arrivals = [3, 1]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
        soft_solution = cooperative_astar(mapf; conflict_price=10)
        @test !is_feasible(soft_solution, mapf)
        @test sum_of_conflicts(soft_solution, mapf) == 2
    end

    @testset "Swapping conflict" begin
        g = path_graph(8)
        departures = [1, 4, 5, 8]
        arrivals = [4, 1, 8, 5]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
        soft_solution = cooperative_astar(mapf; conflict_price=10)
        @test !is_feasible(soft_solution, mapf)
        @test sum_of_conflicts(soft_solution, mapf) == 4
    end

    @testset "Arrival conflict" begin
        # blocked by arrival
        g = path_graph(20)
        departures = [3, 19, 20]
        arrivals = [3, 1, 2]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
        soft_solution = cooperative_astar(mapf; conflict_price=10)
        @test !is_feasible(soft_solution, mapf)
        @test sum_of_conflicts(soft_solution, mapf) == 4

        # zig-zag
        g = path_graph(4)
        departures = [4, 1]
        arrivals = [1, 2]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
    end

    @testset "Infinite loop" begin
        g = path_graph(4)
        for v in 1:4
            add_edge!(g, v, v)
        end
        departures = [1, 4]
        arrivals = [2, 1]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
    end

    @testset "Conflict price" begin
        g = blockdiag(star_graph(4), star_graph(4))
        add_edge!(g, 1, 5)
        departures = [2, 3, 4]
        arrivals = [6, 7, 8]
        mapf = MAPF(g, departures, arrivals)
        @test_throws NoConflictFreePathError cooperative_astar(mapf)
        soft_solution = cooperative_astar(mapf; conflict_price=1)
        @test !is_feasible(soft_solution, mapf)
        @test sum_of_conflicts(soft_solution, mapf) == 6
        soft_solution = cooperative_astar(mapf; conflict_price=100)
        @test !is_feasible(soft_solution, mapf)
        @test sum_of_conflicts(soft_solution, mapf) == 5
    end
end

@testset "Inconsistent graphs" begin
    @test_throws AssertionError MAPF(Graph(3), [3, 2], [1])
    @test_throws AssertionError MAPF(Graph(3), [3], [4])
    @test_throws AssertionError MAPF(Graph(3), [4], [3])
end

@testset "Error printing" begin
    e = NoPathError(1, 2)
    @test sprint(showerror, e) ==
        "NoPathError: There is no path from vertex 1 to vertex 2 in the graph"

    e = NoConflictFreePathError(1, 2)
    @test sprint(showerror, e) ==
        "NoConflictFreePathError: No conflict-free path was found from vertex 1 to vertex 2 in the graph, given the provided reservation."
end

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

    f_indep = sum_of_costs(sol_indep, mapf)
    f_coop = sum_of_costs(sol_coop, mapf)
    @test f_indep <= f_coop
end
