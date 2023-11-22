using MultiAgentPathFinding
using Documenter

DocMeta.setdocmeta!(
    MultiAgentPathFinding, :DocTestSetup, :(using MultiAgentPathFinding); recursive=true
)

cp(
    joinpath(dirname(@__DIR__), "README.md"),
    joinpath(@__DIR__, "src", "index.md");
    force=true,
)

makedocs(;
    modules=[MultiAgentPathFinding],
    authors="Guillaume Dalle and contributors",
    sitename="MultiAgentPathFinding.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        repolink="https://github.com/gdalle/MultiAgentPathFinding.jl",
        canonical="https://gdalle.github.io/MultiAgentPathFinding.jl",
        assets=String[],
    ),
    pages=["Home" => "index.md", "API reference" => "api.md"],
)

deploydocs(; repo="github.com/gdalle/MultiAgentPathFinding.jl", devbranch="main")
