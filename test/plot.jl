using MultiAgentPathFinding
using CairoMakie
using Test

@testset "Static" begin
    scen = BenchmarkScenario(; instance="empty-8-8", scen_type="even", type_id=1, agents=10)
    solution = Solution(scen)
    @test plot_mapf(scen, solution; time=2) isa Figure
    @test plot_mapf(scen, solution; video_path="$(tempname()).mp4") isa String

    scen = BenchmarkScenario(;
        instance="random-32-32-20", scen_type="even", type_id=1, agents=10
    )
    @test plot_mapf(scen) isa Figure
end
