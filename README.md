# MultiAgentPathFinding

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gdalle.github.io/MultiAgentPathFinding.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gdalle.github.io/MultiAgentPathFinding.jl/dev)
[![Build Status](https://github.com/gdalle/MultiAgentPathFinding.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/gdalle/MultiAgentPathFinding.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/gdalle/MultiAgentPathFinding.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/gdalle/MultiAgentPathFinding.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

Fast algorithms for Multi-Agent Path Finding in Julia.

## Getting started

To install this package, open a Julia Pkg REPL and run
```julia
pkg> add https://github.com/gdalle/MultiAgentPathFinding.jl
```

To use the MAPF benchmarks for testing, go to <https://movingai.com/benchmarks/grids.html>, then download and extract zip files corresponding to maps and benchmark problems into the `data/` folder.
File format is described [here](https://webdocs.cs.ualberta.ca/~nathanst/papers/benchmarks.pdf).
We don't provide decoding utilities for the [terrain maps](https://movingai.com/benchmarks/weighted/index.html).

## Related projects

If you're looking for exact methods, check out <https://github.com/Shushman/MultiAgentPathFinding.jl>.
