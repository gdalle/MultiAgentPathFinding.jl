using Aqua
using JET
using JuliaFormatter
using MultiAgentPathFinding
using Test

@testset "Code quality (Aqua)" begin
    Aqua.test_all(MultiAgentPathFinding; ambiguities=false, undocumented_names=true)
end
@testset "Code formatting (JuliaFormatter)" begin
    @test format(MultiAgentPathFinding; verbose=false, overwrite=false)
end
@testset "Code linting (JET)" begin
    #TODO: toggle
    # JET.test_package(MultiAgentPathFinding; target_modules=(MultiAgentPathFinding,))
end
