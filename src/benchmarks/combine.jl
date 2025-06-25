"""
$(TYPEDSIGNATURES)

Construct a `MAPF` instance from a grid map and a list of departure and arrival coordinates.

For the map, each element of the grid can be either

- a `Bool`, in which case `false` denotes passable terrain and `true` denotes an obstacle
- a `Char`, in which case `'.'` denotes passable terrain and `'@'` denotes an obstacle

For the coordinates, `(1, 1)` is the upper left corner of the grid.
"""
function MAPF(
    map_matrix::AbstractMatrix,
    departure_coords::Vector{Tuple{Int,Int}},
    arrival_coords::Vector{Tuple{Int,Int}};
    kwargs...,
)
    g, coord_to_vertex, vertex_to_coord = parse_benchmark_map(map_matrix)
    departures = [coord_to_vertex[is, js] for (is, js) in departure_coords]
    arrivals = [coord_to_vertex[is, js] for (is, js) in arrival_coords]
    return MAPF(g, departures, arrivals; vertex_to_coord, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Create a `MAPF` instance by reading a map (`"something.map"`) and scenario (`"something.scen"`) from files.

See possible names at <https://movingai.com/benchmarks/mapf/index.html> (data will be downloaded automatically).
"""
function MAPF(map_name::AbstractString, scenario_name::AbstractString; check::Bool=false)
    @assert endswith(map_name, ".map")
    @assert endswith(scenario_name, ".scen")
    map_matrix = read_benchmark_map(map_name)
    scenario = read_benchmark_scenario(scenario_name, map_name)
    departure_coords, arrival_coords = parse_benchmark_scenario(scenario)
    mapf = MAPF(map_matrix, departure_coords, arrival_coords)
    if check
        (; g, departures, arrivals) = mapf
        for a in eachindex(scenario, departures, arrivals)
            result = dijkstra(g, departures[a])
            optimal_length_computed = result.dists[arrivals[a]]
            @assert isapprox(optimal_length_computed, scenario[a].optimal_length, rtol=1e-5)
        end
    end
    return mapf
end
