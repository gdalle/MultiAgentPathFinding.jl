# MultiAgentPathFinding

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gdalle.github.io/MultiAgentPathFinding.jl/dev)
[![Build Status](https://github.com/gdalle/MultiAgentPathFinding.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/gdalle/MultiAgentPathFinding.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/gdalle/MultiAgentPathFinding.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/gdalle/MultiAgentPathFinding.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

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
