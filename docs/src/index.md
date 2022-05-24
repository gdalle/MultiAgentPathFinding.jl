```@meta
CurrentModule = MultiAgentPathFinding
```

# MultiAgentPathFinding.jl

This package implements several heuristic solvers for Multi-Agent PathFinding[^1] in the Julia programming language.

[^1]: [*Multi-Agent Pathfinding: Definitions, Variants, and Benchmarks*](https://www.aaai.org/ocs/index.php/SOCS/SOCS19/paper/view/18341), Stern et al. (2019)

## Getting started

Installation is simple: just open a Julia Pkg REPL and run
```julia
pkg> add https://github.com/gdalle/MultiAgentPathFinding.jl
```

## Related projects

Packages using `MultiAgentPathFinding.jl`:

- [`gdalle/MAPFBenchmarks.jl`](https://github.com/gdalle/MAPFBenchmarks.jl): application to standard grid benchmarks
- [`gdalle/Flatland.jl`](https://github.com/gdalle/Flatland.jl): application to the Flatland challenge

Alternative solvers:

- [`Shushman/MultiAgentPathFinding.jl`](https://github.com/Shushman/MultiAgentPathFinding.jl)
