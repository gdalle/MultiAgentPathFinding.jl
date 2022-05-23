const BenchmarkMAPF = MAPF{SparseGridGraph{Int64,Float64}}

is_passable(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

function benchmark_mapf(
    map_path::AbstractString, scenario_path::AbstractString; buckets=1:10
)
    # Read files
    map_matrix = read_benchmark_map(map_path)
    scenario = read_benchmark_scenario(scenario_path, map_path)
    # Create graph
    mask = map(is_passable, map_matrix)
    weights = zeros(Float64, size(mask))
    weights[mask] .= 1.0
    g = SparseGridGraph(weights, mask)
    # Add sources and destinations
    ccs = weakly_connected_components(g)
    largest_cc = ccs[argmax(length.(ccs))]
    sources, destinations = Int[], Int[]
    for pb in scenario
        pb.bucket in buckets || continue
        s = GridGraphs.node_index(g, pb.start_i, pb.start_j)
        d = GridGraphs.node_index(g, pb.goal_i, pb.goal_j)
        if (s in largest_cc) && (d in largest_cc)
            push!(sources, s)
            push!(destinations, d)
        else
            short_scenario_path = joinpath(splitpath(scenario_path)[end-1:end]...)
            index = pb.index
            start_xy = (pb.start_j - 1, pb.start_i - 1)
            goal_xy = (pb.goal_j - 1, pb.goal_i - 1)
            @info "Infeasible problem for scenario $short_scenario_path" index start_xy goal_xy
        end
    end
    # Create MAPF
    mapf = MAPF(g, sources, destinations)
    return mapf
end

function is_solvable(mapf::BenchmarkMAPF)
    (; g, sources, destinations) = mapf
    ccs = connected_components(g)
    largest_cc = ccs[argmax(length.(ccs))]
    for (s, d) in zip(sources, destinations)
        if !(s in largest_cc) || !(d in largest_cc)
            return false
        end
    end
    return true
end
