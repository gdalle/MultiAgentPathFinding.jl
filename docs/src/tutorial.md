# Tutorial

```@example tuto
using Graphs
using MultiAgentPathFinding
```

## Instance creation

A [`MAPF`](@ref) instance can be created from any undirected graph.
Agents are specified by their departure and arrival vertex.

```@example tuto
g = cycle_graph(10)
departures = [1, 3]
arrivals = [4, 1]
mapf = MAPF(g, departures, arrivals)
```

By default, vertex and swapping conflicts are forbidden, and the agents stay at their arrival vertex.

## Solution algorithms

You can compute independent shortest paths with [`independent_dijkstra`](@ref) as follows:

```@example tuto
bad_solution = independent_dijkstra(mapf)
```

The resulting object is a [`Solution`](@ref), with one path per agent.
As you can see, this solution has a conflict:

```@example tuto
is_feasible(bad_solution, mapf)
```

```@example tuto
find_conflict(bad_solution, mapf)
```

Prioritized planning with [`cooperative_astar`](@ref) helps you obtain a solution without conflict:

```@example tuto
good_solution = cooperative_astar(mapf)
```

```@example tuto
is_feasible(good_solution, mapf)
```

You can then evaluate its total path length:

```@example tuto
sum_of_costs(good_solution, mapf)
```

Of course that value depends on the agent ordering chosen for prioritized planning:

```@example tuto
better_solution = cooperative_astar(mapf, [2, 1])
sum_of_costs(better_solution, mapf)
```

## Benchmark dataset

To download and parse an instance from the standard [MAPF benchmarks](https://www.movingai.com/benchmarks/mapf.html), just specify the name of its map and scenario files:

```@example tuto
map_name = "Berlin_1_256.map"
scenario_name = "Berlin_1_256-even-1.scen"
bench_mapf = MAPF(map_name, scenario_name)
```

You can visualize it as follows:

```@example tuto
using MultiAgentPathFinding: read_benchmark_map, cell_color

cell_color.(read_benchmark_map(map_name))
```

If the instance is too big, a subset of agents can be taken:

```@example tuto
select_agents(bench_mapf, 1:100)
```
