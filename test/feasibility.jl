using Graphs
using MultiAgentPathFinding
using Test

@testset "Individually infeasible" begin
    g = path_graph(5)
    departures = [1, 2]
    arrivals = [2, 5]
    mapf = MAPF(g, departures, arrivals)
    incomplete_solution = Solution([[1, 2]])
    @test !is_feasible(incomplete_solution, mapf)
    empty_solution = Solution([[1, 2], Int[]])
    @test !is_feasible(empty_solution, mapf)
    bad_departure_solution = Solution([[1, 2], [3, 4, 5]])
    @test !is_feasible(bad_departure_solution, mapf)
    bad_arrival_solution = Solution([[1, 2], [2, 3, 4]])
    @test !is_feasible(bad_arrival_solution, mapf)
    bad_path_solution = Solution([[1, 2], [2, 3, 5]])
    @test !is_feasible(bad_path_solution, mapf)
end

@testset "Vertex conflict" begin
    g = path_graph(5)
    departures = [1, 3, 4]
    arrivals = [3, 1, 5]
    mapf = MAPF(g, departures, arrivals)
    solution = Solution([[1, 2, 3], [3, 2, 1], [4, 5]])

    reservation = Reservation(solution, mapf)
    @test only(pairs(reservation.multi_occupied_vertices)) == ((2, 2) => [1, 2])
    @test isempty(reservation.multi_occupied_edges)

    @test find_conflict(solution, mapf) == VertexConflict(; t=2, v=2, a1=2, a2=1)
    @test !is_feasible(solution, mapf)

    string(VertexConflict(; t=2, v=2, a1=2, a2=1))
end

@testset "Edge conflict" begin
    g = path_graph(4)
    departures = [1, 4]
    arrivals = [4, 1]
    mapf = MAPF(g, departures, arrivals)
    solution = Solution([[1, 2, 3, 4], [4, 3, 2, 1]])

    reservation = Reservation(solution, mapf)
    @test isempty(reservation.multi_occupied_vertices)
    @test reservation.multi_occupied_edges == Dict((2, 2, 3) => [1, 2], (2, 3, 2) => [1, 2])

    @test find_conflict(solution, mapf) == EdgeConflict(; t=2, u=2, v=3, a1=1, a2=2)
    @test !is_feasible(solution, mapf)

    string(EdgeConflict(; t=2, u=2, v=3, a1=1, a2=2))
end

@testset "Arrival conflict" begin
    g = path_graph(4)
    departures = [1, 4]
    arrivals = [2, 1]
    mapf = MAPF(g, departures, arrivals)
    solution = Solution([[1, 2], [4, 3, 2, 1]])
    reservation = Reservation(solution, mapf)

    @test length(reservation.arrival_vertices) == 2
    @test reservation.arrival_vertices_crossings == Dict(2 => [(3, 2)])

    @test !is_feasible(solution, mapf)
    @test find_conflict(solution, mapf) == VertexConflict(; t=3, v=2, a1=1, a2=2)
end
