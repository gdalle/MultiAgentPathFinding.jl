using Aqua
using JuliaFormatter
using MultiAgentPathFinding
using Test

@testset verbose = true "MultiAgentPathFinding.jl" begin
    @testset "Code quality (Aqua)" begin
        Aqua.test_all(MultiAgentPathFinding; ambiguities=false)
    end
    @testset "Code formatting (JuliaFormatter)" begin
        @test format(MultiAgentPathFinding; verbose=false, overwrite=false)
    end
    @testset verbose = true "Algorithms" begin
        include("algorithms.jl")
    end
end
