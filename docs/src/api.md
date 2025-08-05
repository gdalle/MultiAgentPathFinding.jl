```@meta
CollapsedDocStrings = true
```

# API reference

These symbols are part of the public API, their existence and behavior is guaranteed until the next breaking release.

## Structures

```@docs
MAPF
Solution
```

## Access

```@docs
nb_agents
select_agents
```

## Feasibility and cost

```@docs
sum_of_costs
sum_of_conflicts
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
```

## Visualization

```@docs
plot_mapf
```
