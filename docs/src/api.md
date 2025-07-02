```@meta
CollapsedDocStrings = true
```

# API reference

Only exported names are part of the API.

```@docs
MultiAgentPathFinding
```

## Structures

```@docs
MAPF
Solution
Reservation
```

## Access

```@docs
nb_agents
select_agents
```

## Feasibility and cost

```@docs
path_cost
sum_of_costs
is_feasible
find_conflict
VertexConflict
EdgeConflict
```

## Basic algorithms

```@docs
independent_dijkstra
cooperative_astar
```

## Benchmarks

```@docs
list_instances
BenchmarkScenario
read_benchmark_map
parse_benchmark_map
passable_cell
cell_color
```

## Internals

```@autodocs
Modules = [MultiAgentPathFinding]
Public = false
```

## Index

```@index
```
