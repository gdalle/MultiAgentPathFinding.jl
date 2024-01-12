"""
    read_benchmark_mapf(map_name::AbstractString, scenario_name::AbstractString;)

Create a `MAPF` instance by reading a map (`"something.map"`) and scenario (`"something.scen"`) from files.

See possible names at <https://movingai.com/benchmarks/mapf/index.html> (data will be downloaded automatically).
"""
function read_benchmark(map_name::AbstractString, scenario_name::AbstractString)
    map_matrix = read_benchmark_map(map_name)
    g, coord_to_vertex = parse_benchmark_map(map_matrix)
    scenario = read_benchmark_scenario(scenario_name, map_name)
    departures, arrivals = parse_benchmark_scenario(scenario, coord_to_vertex)
    mapf = MAPF(g; departures=departures, arrivals=arrivals)
    return mapf
end
