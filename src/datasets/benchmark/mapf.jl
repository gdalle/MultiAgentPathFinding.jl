const BenchmarkMAPF = MAPF{SparseGridGraph{Int64,Float64}}

is_passable(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

function benchmark_mapf(map_matrix::Matrix{Char}, scenario::DataFrame; buckets=1:10)
    mask = map(is_passable, map_matrix)
    weights = zeros(Float64, size(mask))
    weights[mask] .= 1.0
    g = SparseGridGraph(weights, mask)
    agents = @rsubset(scenario, :bucket in buckets)
    sources = [GridGraphs.node_index(g, ag.start_i, ag.start_j) for ag in eachrow(agents)]
    destinations = [
        GridGraphs.node_index(g, ag.goal_i, ag.goal_j) for ag in eachrow(agents)
    ]
    mapf = MAPF(g, sources, destinations)
    return mapf
end

function benchmark_mapf(
    map_path::AbstractString, scenario_path::AbstractString; buckets=1:10
)
    map_matrix = read_benchmark_map(map_path)
    scenario = read_benchmark_scenario(scenario_path, map_path)
    return benchmark_mapf(map_matrix, scenario; buckets=buckets)
end

function is_feasible(mapf::BenchmarkMAPF)
    all_connected_components = connected_components(mapf.graph)
    largest_connected_component = all_connected_components[argmax(
        length.(all_connected_components)
    )]
    return all(in(largest_connected_component), mapf.sources) &&
           all(in(largest_connected_component), mapf.destinations)
end
