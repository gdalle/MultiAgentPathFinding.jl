using MultiAgentPathFinding
using Documenter

DocMeta.setdocmeta!(MultiAgentPathFinding, :DocTestSetup, :(using MultiAgentPathFinding); recursive=true)

makedocs(;
    modules=[MultiAgentPathFinding],
    authors="Guillaume Dalle <22795598+gdalle@users.noreply.github.com> and contributors",
    repo="https://github.com/gdalle/MultiAgentPathFinding.jl/blob/{commit}{path}#{line}",
    sitename="MultiAgentPathFinding.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gdalle.github.io/MultiAgentPathFinding.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API reference" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/gdalle/MultiAgentPathFinding.jl",
    devbranch="main",
)
