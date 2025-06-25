using Graphs
using MultiAgentPathFinding
using Test

@testset "Vertex conflict" begin
    g = Graphs.path_graph(5)
    departures = [1, 3, 4]
    arrivals = [3, 1, 5]
    mapf = MAPF(g, departures, arrivals)
    solution = Solution([[1, 2, 3], [3, 2, 1], [4, 5]])

    reservation = Reservation(solution, mapf)
    @test only(pairs(reservation.multi_occupied_vertices)) == ((2, 2) => [1, 2])
    @test isempty(reservation.multi_occupied_edges)

    @test find_conflict(solution, mapf) isa VertexConflict
end

@testset "Edge conflict" begin
    g = Graphs.path_graph(5)
    departures = [1, 2, 4]
    arrivals = [2, 1, 5]
    mapf = MAPF(g, departures, arrivals)
    solution = Solution([[1, 2], [2, 1], [4, 5]])

    reservation = Reservation(solution, mapf)
    @test isempty(reservation.multi_occupied_vertices)
    @test reservation.multi_occupied_edges == Dict((1, 1, 2) => [1, 2], (1, 2, 1) => [1, 2])

    @test find_conflict(solution, mapf) isa EdgeConflict
end
