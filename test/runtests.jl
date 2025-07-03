using MultiAgentPathFinding
using Test

ENV["DATADEPS_ALWAYS_ACCEPT"] = get(ENV, "CI", "false") == "true"

@testset verbose = true "MultiAgentPathFinding.jl" begin
    @testset verbose = true "Formalities" begin
        include("formalities.jl")
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
    @testset verbose = true "Plot" begin
        include("plot.jl")
    end
end
