using MultiAgentPathFinding
using MultiAgentPathFinding:
    read_benchmark_map, read_benchmark_scenario, parse_benchmark_map, cell_color
using MultiAgentPathFinding: cooperative_astar
using Graphs
using SparseArrays
using Test

@testset "Berlin" begin
    instance = "Berlin_1_256"
    scen_type = "even"
    type_id = 1
    agents = 100
    scen = BenchmarkScenario(; instance, scen_type, type_id, agents)

    mapf = MAPF(scen; check=true)
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
    scen = BenchmarkScenario(;
        instance="Berlin_1_256", scen_type="even", type_id=2, agents=10
    )
    mapf = MAPF(scen)
    @test nb_agents(mapf) == 10
    smaller_mapf = select_agents(mapf, 1:6)
    @test nb_agents(smaller_mapf) == 6
end
