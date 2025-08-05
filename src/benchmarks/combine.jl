"""
    MAPF(
        grid::AbstractMatrix,
        departure_coords::Vector{Tuple{Int,Int}},
        arrival_coords::Vector{Tuple{Int,Int}};
        allow_diagonal_moves::Bool=false,
    )

Construct a `MAPF` instance from a grid map and a list of departure and arrival coordinates.

Each element of the grid can be either

- a `Bool`, in which case `false` denotes passable terrain and `true` denotes an obstacle
- a `Char`, in which case `'.'` denotes passable terrain and `'@'` denotes an obstacle

Regarding the coordinates, `(i, j)` corresponds to row `i` and column `j` (with `(1, 1)` as the upper-left corner).
"""
function MAPF(
    grid::AbstractMatrix,
    departure_coords::Vector{Tuple{Int,Int}},
    arrival_coords::Vector{Tuple{Int,Int}};
    allow_diagonal_moves::Bool=false,
    kwargs...,
)
    g, coord_to_vertex, vertex_to_coord = parse_benchmark_map(grid; allow_diagonal_moves)
    departures = [coord_to_vertex[is, js] for (is, js) in departure_coords]
    arrivals = [coord_to_vertex[is, js] for (is, js) in arrival_coords]
    return MAPF(g, departures, arrivals; kwargs...)
end

"""
    MAPF(scen::BenchmarkScenario; allow_diagonal_moves::Bool=false)

Create a `MAPF` instance by reading a map and scenario from automatically downloaded benchmark files.
"""
function MAPF(scen::BenchmarkScenario; allow_diagonal_moves::Bool=false, check::Bool=false)
    grid = read_benchmark_map(scen.instance)
    agent_list = read_benchmark_scenario(scen)
    departure_coords = map(agent -> (agent.start_i, agent.start_j), agent_list)
    arrival_coords = map(agent -> (agent.goal_i, agent.goal_j), agent_list)
    mapf = MAPF(grid, departure_coords, arrival_coords; allow_diagonal_moves)
    if check && allow_diagonal_moves
        (; graph, departures, arrivals) = mapf
        for a in eachindex(agent_list, departures, arrivals)
            result = dijkstra(graph, departures[a])
            optimal_length_computed = result.dists[arrivals[a]]
            @assert isapprox(
                optimal_length_computed, agent_list[a].optimal_length, rtol=1e-5
            )
        end
    end
    return mapf
end

"""
    Solution(scen::BenchmarkScenario)

Create a `MAPF` instance by reading a map and solution from automatically downloaded benchmark files.

!!! warning
    The downloaded files can be large (up to tens of GB).
    By default, DataDeps.jl will ask for permission in the REPL before downloading.
"""
function Solution(scen::BenchmarkScenario; check::Bool=false)
    grid = read_benchmark_map(scen.instance)
    _, coord_to_vertex, _ = parse_benchmark_map(grid; allow_diagonal_moves=false)
    lower_cost, solution_cost, paths_coord_list = read_benchmark_solution(scen)
    solution = Solution(
        map(path_coord -> getindex.(Ref(coord_to_vertex), path_coord), paths_coord_list)
    )
    if check
        mapf = MAPF(scen)
        @assert is_feasible(solution, mapf; verbose=true)
        @assert lower_cost <= sum_of_costs(solution, mapf) == solution_cost
    end
    return solution
end
