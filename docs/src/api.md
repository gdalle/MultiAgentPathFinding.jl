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
Conflict
```

## Access

```@docs
nb_agents
select_agents
```

## Feasibility and cost

```@docs
flowtime
is_feasible
find_conflict
```

## Basic algorithms

```@docs
independent_dijkstra
cooperative_astar
```

## Local search

```@docs
repeated_cooperative_astar
feasibility_search
optimality_search
double_search
```

## Benchmarks

```@docs
read_benchmark
```

## Internals

```@autodocs
Modules = [MultiAgentPathFinding]
Public = false
```

## Index

```@index
```
