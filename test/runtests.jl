using MultiAgentPathFinding
using Test

@testset verbose = true "MultiAgentPathFinding.jl" begin
    @testset verbose = true "Flatland instances" begin
        include("flatland.jl")
    end
    @testset verbose = true "Benchmark instances" begin
        include("benchmark.jl")
    end
end
