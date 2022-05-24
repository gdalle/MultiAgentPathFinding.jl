# API reference

## Types

```@autodocs
Modules = [MultiAgentPathFinding]
Pages = [
    "structs/mapf.jl",
    "structs/path.jl",
    "structs/reservation.jl",
    "structs/solution.jl"
]
```

## Shortest paths

```@autodocs
Modules = [MultiAgentPathFinding]
Pages = [
    "paths/bellman_ford.jl",
    "paths/cooperative_astar.jl",
    "paths/dijkstra.jl",
    "paths/independent_dijkstra.jl",
    "paths/temporal_astar.jl",
]
```

## Local search

```@autodocs
Modules = [MultiAgentPathFinding]
Pages = [
    "local_search/feasibility_search.jl",
    "local_search/large_neighborhood_search.jl",
    "local_search/neighborhood.jl",
]
```

## Solution evaluation

```@autodocs
Modules = [MultiAgentPathFinding]
Pages = [
    "eval/conflicts.jl",
    "eval/cost.jl",
    "eval/feasibility.jl",
]
```

## Embedding

```@autodocs
Modules = [MultiAgentPathFinding]
Pages = [
    "embedding/features_agents.jl",
    "embedding/features_edges.jl",
    "embedding/features_both.jl",
    "embedding/embedding.jl",
]
```

## Index

```@index
```