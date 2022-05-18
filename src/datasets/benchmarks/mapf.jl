is_passable(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

function benchmark_mapf(char_matrix::Matrix{Char}, scenario::DataFrame; bucket=1)
    mask = map(is_passable, char_matrix)
    weights = zeros(Float64, size(mask))
    weights[mask] .= 1.0
    g = SparseGridGraph(weights, mask)
    all_connected_components = connected_components(g)
    largest_connected_component = all_connected_components[argmax(length.(all_connected_components))]

    agents = @rsubset(scenario, :bucket == bucket)
    sources = [GridGraphs.node_index(g, ag.start_i, ag.start_j) for ag in eachrow(agents)]
    destinations = [
        GridGraphs.node_index(g, ag.goal_i, ag.goal_j) for ag in eachrow(agents)
    ]
    @assert all(in(largest_connected_component), sources)
    @assert all(in(largest_connected_component), destinations)
    mapf = MAPF(; graph=g, sources=sources, destinations=destinations)
    return mapf
end

function benchmark_mapf(map_path::AbstractString, scen_path::AbstractString; bucket=1)
    char_matrix = read_benchmark_map(map_path)
    scenario = read_benchmark_scenario(scen_path)
    return benchmark_mapf(char_matrix, scenario; bucket=bucket)
end
