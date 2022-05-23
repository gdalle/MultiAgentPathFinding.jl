```@meta
CurrentModule = MultiAgentPathFinding
```

# MultiAgentPathFinding.jl

This package implements several heuristic solvers for Multi-Agent PathFinding[^1] in the Julia programming language.

## Getting started

Installation is simple: just open a Julia Pkg REPL and run
```julia
pkg> add https://github.com/gdalle/MultiAgentPathFinding.jl
```

## Benchmark data

To use instances from Sturtevant's grid-based MAPF benchmark[^2], you need to:

1. clone the repository
2. go to <https://movingai.com/benchmarks/grids.html>
3. download and extract the zip files for both maps and benchmark problems into the `data/` folder

The file format is described [here](https://webdocs.cs.ualberta.ca/~nathanst/papers/benchmarks.pdf).
Note that we don't support [terrain maps](https://movingai.com/benchmarks/weighted/index.html) yet.

## Related projects

If you're looking for exact MAPF solvers, check out <https://github.com/Shushman/MultiAgentPathFinding.jl>.

[^1]: [*Multi-Agent Pathfinding: Definitions, Variants, and Benchmarks*](https://www.aaai.org/ocs/index.php/SOCS/SOCS19/paper/view/18341), Stern et al. (2019)

[^2]: [*Benchmarks for Grid-Based Pathfinding*](https://ieeexplore.ieee.org/document/6194296), Sturtevant (2012)
