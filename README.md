# MultiAgentPathFinding

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gdalle.github.io/MultiAgentPathFinding.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gdalle.github.io/MultiAgentPathFinding.jl/dev)
[![Build Status](https://github.com/gdalle/MultiAgentPathFinding.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/gdalle/MultiAgentPathFinding.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/gdalle/MultiAgentPathFinding.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/gdalle/MultiAgentPathFinding.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

This package provides a toolbox for defining and solving multi-agent pathfinding problems in the Julia programming language.

## Getting started

For the latest stable version, open a Julia Pkg REPL and run

```julia
pkg> add MultiAgentPathFinding
```

For the development version, run

```julia
pkg> add https://github.com/gdalle/MultiAgentPathFinding.jl
```

For now the documentation is a bit lacking, but take a look at the files in [`test`](https://github.com/gdalle/MultiAgentPathFinding.jl/tree/main/test) for usage examples.

## Background

MultiAgentPathFinding.jl contains basic optimization algorithms related to multi-agent pathfinding, as well as a parser for the standard benchmark instances described in

> [*Multi-Agent Pathfinding: Definitions, Variants, and Benchmarks*](https://www.aaai.org/ocs/index.php/SOCS/SOCS19/paper/view/18341), Stern et al. (2019)

If you use this package, please cite the following PhD dissertation:

> [*Machine learning and combinatorial optimization algorithms, with applications to railway planning*](https://pastel.hal.science/tel-04053322), Dalle (2022)

## Related projects

Alternative solvers:

- [Shushman/MultiAgentPathFinding.jl](https://github.com/Shushman/MultiAgentPathFinding.jl): conflict-based search
