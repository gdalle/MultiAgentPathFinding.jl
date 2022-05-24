"""
    BenchmarkMAPF = MAPF{SparseGridGraph{Int64,Float64}}

Concrete subtype of [`MAPF`](@ref) designed for the benchmark instances of Sturtevant.
"""
const BenchmarkMAPF = MAPF{SparseGridGraph{Int64,Float64}}

is_passable(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

"""
    benchmark_mapf(map_path, scenario_path[; buckets])
"""
function benchmark_mapf(
    map_path::AbstractString, scenario_path::AbstractString; buckets=1:10
)
    # Read files
    map_matrix = read_benchmark_map(map_path)
    scenario = read_benchmark_scenario(scenario_path, map_path)
    scen = joinpath(splitpath(scenario_path)[(end - 1):end]...)
    # Create graph
    mask = map(is_passable, map_matrix)
    weights = zeros(Float64, size(mask))
    weights[mask] .= 1.0
    g = SparseGridGraph(weights, mask)
    # Add sources and destinations
    ccs = weakly_connected_components(g)
    k_largest = argmax(length.(ccs))
    sources, destinations = Int[], Int[]
    for pb in scenario
        problem = pb.index
        pb.bucket in buckets || continue
        is, js = pb.start_i, pb.start_j
        id, jd = pb.goal_i, pb.goal_j
        s = GridGraphs.node_index(g, is, js)
        d = GridGraphs.node_index(g, id, jd)

        k_s, k_d = -1, -2
        for (k, cc) in enumerate(ccs)
            if insorted(s, cc)
                k_s = k
            end
            if insorted(d, cc)
                k_d = k
            end
            if k_s != -1 && k_d != -2
                break
            end
        end
        if !active_vertex(g, s)
            @info "Inactive start vertex" scen problem (is, js)
        elseif !active_vertex(g, d)
            @info "Inactive goal vertex" scen problem (id, jd)
        elseif k_s != k_d
            @info "Start and goal vertex in different connected components" scen problem (is, js) (id, jd) k_s k_d
        # elseif k_s != k_largest || k_d != k_largest
        #     @info "Start and goal vertex in a small connected component" scen problem (is, js) (id, jd)
        else
            push!(sources, s)
            push!(destinations, d)
        end
    end
    # Create MAPF
    mapf = MAPF(g, sources, destinations)
    return mapf
end
