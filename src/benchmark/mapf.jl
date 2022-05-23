const BenchmarkMAPF = MAPF{SparseGridGraph{Int64,Float64}}

is_passable(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

function benchmark_mapf(
    map_matrix::Matrix{Char}, scenario::Vector{BenchmarkProblem}; buckets=1:10
)
    mask = map(is_passable, map_matrix)
    weights = zeros(Float64, size(mask))
    weights[mask] .= 1.0
    g = SparseGridGraph(weights, mask)
    sources = [
        GridGraphs.node_index(g, pb.start_i, pb.start_j) for
        pb in scenario if pb.bucket in buckets
    ]
    destinations = [
        GridGraphs.node_index(g, pb.goal_i, pb.goal_j) for
        pb in scenario if pb.bucket in buckets
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

function is_solvable(mapf::BenchmarkMAPF)
    all_connected_components = connected_components(mapf.g)
    largest_connected_component = all_connected_components[argmax(
        length.(all_connected_components)
    )]
    return all(in(largest_connected_component), mapf.sources) &&
           all(in(largest_connected_component), mapf.destinations)
end
