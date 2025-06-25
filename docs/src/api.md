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
TimedPath
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
solution_cost
is_feasible
find_conflict
VertexConflict
EdgeConflict
```

## Basic algorithms

```@docs
dijkstra_by_arrival
independent_dijkstra
cooperative_astar
```

## Benchmarks

```@docs
read_benchmark
list_map_names
list_scenario_names
```

## Internals

```@autodocs
Modules = [MultiAgentPathFinding]
Public = false
```

## Index

```@index
```
