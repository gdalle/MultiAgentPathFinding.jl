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
    map_name = "Berlin_1_256.map"
    scenario_name = "Berlin_1_256-even-1.scen"

    map_matrix = read_benchmark_map(map_name)
    g, coord_to_vertex = parse_benchmark_map(map_matrix)
    scenario = read_benchmark_scenario(scenario_name, map_name)
    departure_coords, arrival_coords = parse_benchmark_scenario(scenario)
    mapf = MAPF(map_name, scenario_name; check=true)

    @test size(map_matrix) == (256, 256)
    @test nv(g) == 47540
    @test nb_agents(mapf) == 950
    A = nb_agents(mapf)

    sol_indep = independent_dijkstra(mapf)

    sol_coop = cooperative_astar(mapf, 1:A)

    @test !is_feasible(sol_indep, mapf)
    @test is_feasible(sol_coop, mapf)

    f_indep = solution_cost(sol_indep, mapf)
    f_coop = solution_cost(sol_coop, mapf)
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
