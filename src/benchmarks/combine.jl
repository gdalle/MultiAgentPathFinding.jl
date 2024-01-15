"""
$(TYPEDSIGNATURES)

Create a `MAPF` instance by reading a map (`"something.map"`) and scenario (`"something.scen"`) from files.

See possible names at <https://movingai.com/benchmarks/mapf/index.html> (data will be downloaded automatically).
"""
function read_benchmark(
    map_name::AbstractString, scenario_name::AbstractString; check::Bool=false
)
    map_matrix = read_benchmark_map(map_name)
    g, coord_to_vertex = parse_benchmark_map(map_matrix)
    scenario = read_benchmark_scenario(scenario_name, map_name)
    departures, arrivals = parse_benchmark_scenario(scenario, coord_to_vertex)
    mapf = MAPF(g; departures=departures, arrivals=arrivals)
    if check
        sol_indep = independent_dijkstra(mapf; show_progress=true)
        for a in 1:length(sol_indep)
            @assert path_cost(sol_indep[a], mapf) ≈ scenario[a].optimal_length
        end
    end
    return mapf
end
