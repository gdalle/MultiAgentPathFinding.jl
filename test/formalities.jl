using Aqua
using MultiAgentPathFinding
using Test

@testset "Code quality (Aqua)" begin
    Aqua.test_all(MultiAgentPathFinding; ambiguities=false, undocumented_names=true)
end
