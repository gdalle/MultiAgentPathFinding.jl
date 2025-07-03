using MultiAgentPathFinding
using MultiAgentPathFinding: cell_color
using MultiAgentPathFinding: MissingScenarioError, MissingSolutionError
using Graphs
using SparseArrays
using Test

@test length(list_instances()) == 33

@testset "Berlin" begin
    instance = "Berlin_1_256"
    scen_type = "even"
    type_id = 1
    agents = 100
    scen = BenchmarkScenario(; instance, scen_type, type_id, agents)

    mapf = MAPF(scen; allow_diagonal_moves=true, check=true)
    grid = read_benchmark_map(instance)
    string(mapf)

    @test size(grid) == (256, 256)
    @test nv(mapf.graph) == 47540
    @test nb_agents(mapf) == agents

    sol_indep = independent_dijkstra(mapf)
    sol_coop = cooperative_astar(mapf, reverse(1:agents))

    @test !is_feasible(sol_indep, mapf)
    @test is_feasible(sol_coop, mapf)

    f_indep = sum_of_costs(sol_indep, mapf)
    f_coop = sum_of_costs(sol_coop, mapf)
    @test f_indep <= f_coop
end

@testset "Optimal solution" begin
    instance = "empty-8-8"
    scen_type = "even"
    @testset for type_id in 1:2
        @testset for agents in 10:10:100
            scen = BenchmarkScenario(; instance, scen_type, type_id, agents)

            mapf = MAPF(scen; check=true)

            sol_indep = independent_dijkstra(mapf)
            sol_coop = cooperative_astar(mapf)
            sol_opt = Solution(scen; check=true)

            @test is_feasible(sol_coop, mapf)
            @test is_feasible(sol_opt, mapf)

            f_indep = sum_of_costs(sol_indep, mapf)
            f_coop = sum_of_costs(sol_coop, mapf)
            f_opt = sum_of_costs(sol_opt, mapf)

            @test f_indep <= f_opt
            @test f_opt <= f_coop
        end
    end
end;

@testset "Colors" begin
    grid = read_benchmark_map("brc202d")
    @test length(unique(cell_color.(grid))) == 3
end

@testset "Boolean matrix" begin
    A = zeros(Bool, 10, 10)
    A[2, 3] = 1
    departure_coords = [(1, 1)]
    arrival_coords = [(10, 10)]
    mapf = MAPF(A, departure_coords, arrival_coords)
    @test nv(mapf.graph) == 99
end

@testset "Coordinates" begin
    grid = read_benchmark_map("Berlin_1_256")
    (; graph, coord_to_vertex, vertex_to_coord) = parse_benchmark_map(grid)

    @test vertex_to_coord[1] == (1, 1)
    @test vertex_to_coord[end] == (256, 256)
end

@testset "Agent subset" begin
    scen = BenchmarkScenario(; instance="Berlin_1_256", scen_type="even", type_id=1)
    mapf = MAPF(scen)
    @test nb_agents(mapf) == 950
    scen = BenchmarkScenario(;
        instance="Berlin_1_256", scen_type="even", type_id=1, agents=10
    )
    mapf = MAPF(scen)
    @test nb_agents(mapf) == 10
    smaller_mapf = select_agents(mapf, 1:6)
    @test nb_agents(smaller_mapf) == 6
end

@testset "Errors" begin
    @test_throws AssertionError BenchmarkScenario(;
        instance="empty-8-8", scen_type="plop", type_id=100, agents=10
    )

    scen = BenchmarkScenario(; instance="empty-8-9", scen_type="even", type_id=1, agents=1)
    @test_throws SystemError MAPF(scen)
    scen = BenchmarkScenario(;
        instance="empty-8-8", scen_type="even", type_id=1000, agents=1
    )
    @test_throws SystemError MAPF(scen)
    scen = BenchmarkScenario(;
        instance="empty-8-8", scen_type="even", type_id=1, agents=1000
    )
    @test_throws MissingScenarioError MAPF(scen)

    scen = BenchmarkScenario(;
        instance="empty-8-8", scen_type="even", type_id=1000, agents=1
    )
    @test_throws MissingSolutionError Solution(scen)
    scen = BenchmarkScenario(;
        instance="empty-8-8", scen_type="even", type_id=1, agents=1000
    )
    @test_throws MissingSolutionError Solution(scen)
end
