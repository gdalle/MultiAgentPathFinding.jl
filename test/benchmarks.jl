using MultiAgentPathFinding
using MultiAgentPathFinding:
    read_benchmark_map,
    read_benchmark_scenario,
    parse_benchmark_map,
    parse_benchmark_scenario,
    cell_color,
    map_from_scenario,
    scenarios_from_map
using MultiAgentPathFinding: cooperative_astar
using Graphs
using SparseArrays
using Test

## Test one scenario

@testset "Berlin" begin
    instance = "Berlin_1_256"
    scen_type = "even"
    type_id = 1
    agents = 950
    scen = BenchmarkScenario(; instance, scen_type, type_id, agents)

    mapf = MAPF(scen; check=true)
    grid, _, _ = read_benchmark_map(instance)
    string(mapf)

    @test size(grid) == (256, 256)
    @test nv(mapf.graph) == 47540
    @test nb_agents(mapf) == 950
    A = nb_agents(mapf)

    sol_indep = independent_dijkstra(mapf)
    sol_coop = cooperative_astar(mapf, 1:A)

    @test !is_feasible(sol_indep, mapf)
    @test is_feasible(sol_coop, mapf)

    f_indep = sum_of_costs(sol_indep, mapf)
    f_coop = sum_of_costs(sol_coop, mapf)
    @test f_indep <= f_coop
end

## Test all scenarios

@testset "Coherent lists" begin
    list1 = sort([
        (map_name, scenario_name) for map_name in list_map_names() for
        scenario_name in scenarios_from_map(map_name, "even")
    ])
    list2 = sort([
        (map_from_scenario(scenario_name), scenario_name) for
        scenario_name in list_scenario_names("even")
    ])
    @test list1 == list2
end

@testset "Reading benchmarks" begin
    @testset for map_name in list_map_names()
        for scenario_name in scenarios_from_map(map_name, "even")
            MAPF(map_name, scenario_name)
        end
    end
end

@testset "Colors" begin
    map_name = "brc202d.map"
    @test length(unique(cell_color.(read_benchmark_map(map_name)))) == 3
end

@testset "Boolean matrix" begin
    A = zeros(Bool, 10, 10)
    A[2, 3] = 1
    departure_coords = [(1, 1)]
    arrival_coords = [(10, 10)]
    mapf = MAPF(A, departure_coords, arrival_coords)
    @test nv(mapf.g) == 99
end

@testset "Coordinates" begin
    map_name = "Berlin_1_256.map"
    scenario_name = "Berlin_1_256-even-1.scen"
    mapf = MAPF(map_name, scenario_name)

    @test mapf.vertex_to_coord[1] == (1, 1)
    @test mapf.vertex_to_coord[end] == (256, 256)
end

@testset "Agent subset" begin
    map_name = "Berlin_1_256.map"
    scenario_name = "Berlin_1_256-even-1.scen"
    mapf = MAPF(map_name, scenario_name)
    small_mapf = select_agents(mapf, 1:100)
    @test nb_agents(small_mapf) == 100
end
