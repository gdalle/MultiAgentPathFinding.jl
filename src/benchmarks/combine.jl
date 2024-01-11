"""
    read_benchmark_mapf(map_name::AbstractString, scenario_name::AbstractString;)

Create a `MAPF` instance by reading a map (`"something.map"`) and scenario (`"something.scen"`) from files.

# Example

```jldoctest
using Graphs, MultiAgentPathFinding
mapf = read_benchmark_mapf("Berlin_1_256.map", "Berlin_1_256-random-1.scen")
nv(mapf.g), nb_agents(mapf)

# output

(65536, 1000)
```
"""
function read_benchmark(map_name::AbstractString, scenario_name::AbstractString)
    map_matrix = read_benchmark_map(map_name)
    g, coord_to_vertex = parse_benchmark_map(map_matrix)

    scenario = read_benchmark_scenario(scenario_name, map_name)
    departures, arrivals = parse_benchmark_scenario(scenario, coord_to_vertex)

    mapf = MAPF(
        g;
        departures=departures,
        arrivals=arrivals,
        vertex_conflicts=LazyVertexConflicts(),
        edge_conflicts=LazySwappingConflicts(),
    )
    return mapf
end
