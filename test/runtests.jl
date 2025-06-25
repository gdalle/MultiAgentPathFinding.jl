using Aqua
using JET
using JuliaFormatter
using MultiAgentPathFinding
using Test

ENV["DATADEPS_ALWAYS_ACCEPT"] = get(ENV, "CI", "false") == "true"

@testset verbose = true "MultiAgentPathFinding.jl" begin
    @testset "Code quality (Aqua)" begin
        Aqua.test_all(MultiAgentPathFinding; ambiguities=false)
    end
    @testset "Code formatting (JuliaFormatter)" begin
        @test format(MultiAgentPathFinding; verbose=false, overwrite=false)
    end
    @testset "Code linting (JET)" begin
        JET.test_package(MultiAgentPathFinding; target_defined_modules=true)
    end
    @testset verbose = true "Feasibility" begin
        include("feasibility.jl")
    end
    @testset verbose = true "Algorithms" begin
        include("algorithms.jl")
    end
    @testset verbose = true "Benchmarks" begin
        include("benchmarks.jl")
    end
end
