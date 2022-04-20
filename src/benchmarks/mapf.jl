function benchmark_mapf(map_matrix::Matrix{Char}, scenario::DataFrame; bucket::Integer=1)
    g = GridGraph(map_matrix)
    agents = @rsubset(scenario, :bucket == bucket)
    sources = [node_index(g, ag.start_i, ag.start_j) for ag in eachrow(agents)]
    destinations = [node_index(g, ag.goal_i, ag.goal_j) for ag in eachrow(agents)]
    starting_times = zeros(Int, nrow(agents))
    mapf = MAPF(;
        graph=g,
        sources=sources,
        destinations=destinations,
        starting_times=starting_times,
    )
    return mapf
end
