# Tutorial

```@example tuto
using Graphs
using MultiAgentPathFinding
using CairoMakie
```

## Instance creation

A [`MAPF`](@ref) instance can be created from any undirected graph.
Agents are specified by their departure and arrival vertex.

```@example tuto
graph = cycle_graph(10)
departures = [1, 3]
arrivals = [4, 1]
mapf = MAPF(graph, departures, arrivals)
```

By default, vertex and swapping conflicts are forbidden, and the agents stay at their arrival vertex.
Another constructor is available that works with a grid and lists of coordinate tuples instead.

## Solution algorithms

You can compute independent shortest paths with [`independent_dijkstra`](@ref) as follows:

```@example tuto
bad_solution = independent_dijkstra(mapf)
```

The resulting object is a [`Solution`](@ref), with one path per agent.
As you can see from the output of [`is_feasible`](@ref), this solution has a conflict:

```@example tuto
is_feasible(bad_solution, mapf)
```

To identify it, just call [`find_conflict`](@ref):

```@example tuto
find_conflict(bad_solution, mapf)
```

Prioritized planning with [`cooperative_astar`](@ref) helps you obtain a solution without conflict, at least when the instance is easy enough:

```@example tuto
good_solution = cooperative_astar(mapf)
```

```@example tuto
is_feasible(good_solution, mapf)
```

You can then evaluate its total path length with [`sum_of_costs`](@ref):

```@example tuto
sum_of_costs(good_solution, mapf)
```

Of course that value depends on the agent ordering chosen for prioritized planning:

```@example tuto
better_solution = cooperative_astar(mapf, [2, 1])
sum_of_costs(better_solution, mapf)
```

## Benchmark dataset

To download and parse an instance from the standard [MAPF benchmarks](https://www.movingai.com/benchmarks/mapf.html), just specify the name of its map and the details of its scenario inside a [`BenchmarkScenario`](@ref):

```@example tuto
instance = "Berlin_1_256"
scen_type = "even"
type_id = 1
agents = 100
scen = BenchmarkScenario(; instance, scen_type, type_id, agents)
```

Then, the [`MAPF`](@ref) constructor will prompte you before downloading the necessary files:

```@example tuto
bench_mapf = MAPF(scen; allow_diagonal_moves=true)
```

You can visualize an instance with [`plot_mapf`](@ref):

```@example tuto
plot_mapf(scen)
```

Best known solutions are also available for some instances thanks to the website [Tracking Progress in MAPF](https://tracker.pathfinding.ai/).
The [`Solution`](@ref) constructor will automatically download the necessary data:

```@example tuto
small_scen = BenchmarkScenario(; instance="empty-8-8", scen_type="even", type_id=1, agents=32)
benchmark_solution_best = Solution(small_scen)
```

!!! warning
    The solution files for some instances can be very large (tens of GBs), so think before you validate the download.

For these grid instances, solutions can be visualized at any point in their time span, or recorded as an animation:

```@example tuto
plot_mapf(small_scen, benchmark_solution_best; video_path=joinpath(@__DIR__, "solution.mp4"))
```

```@raw html
<video src="../solution.mp4" width="700" height="700" controls></video>
```
