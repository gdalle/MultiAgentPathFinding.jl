using MultiAgentPathFinding
using CairoMakie
using Test

@testset "Visualization" begin
    scen = BenchmarkScenario(; instance="empty-8-8", scen_type="even", type_id=1, agents=10)
    mapf = MAPF(scen)
    solution = Solution(scen)
    @test visualize_solution(scen, solution, 2) isa Figure
end
