function constant_features_agent(a::Integer, mapf::MAPF)
    t0 = mapf.starting_times[a]
    s = mapf.sources[a]
    d = mapf.destinations[a]
    dist = mapf.distances_to_destinations[d][s]
    return Float64[a, t0, dist]
end

function path_features_agent(a::Integer, solution::Solution, mapf::MAPF)
    path = solution[a]
    g = mapf.graph
    duration = length(path)
    weight = path_weight(path, mapf)
    mean_outdegree = mean(outdegree(g, v) for (t, v) in path)
    mean_indegree = mean(indegree(g, v) for (t, v) in path)
    return Float64[duration, weight, mean_indegree, mean_outdegree]
end

function conflict_features_agent(a::Integer, solution::Solution, mapf::MAPF)
    A = nb_agents(mapf)
    conflicts0 = count_conflicts(a, solution, mapf; tol=0) / 1
    conflicts1 = count_conflicts(a, solution, mapf; tol=1) / 3
    conflicts2 = count_conflicts(a, solution, mapf; tol=2) / 5
    conflicts3 = count_conflicts(a, solution, mapf; tol=3) / 7
    crossings = count_conflicts(a, solution, mapf; tol=Inf)
    return (1 / A) .* Float64[conflicts0, conflicts1, conflicts2, conflicts3, crossings]
end

function all_features_agent(a::Integer, solution::Solution, mapf::MAPF)
    return vcat(
        constant_features_agent(a, mapf),
        path_features_agent(a, solution, mapf),
        conflict_features_agent(a, solution, mapf),
    )
end

function agents_embedding(mapf::MAPF)
    solution = independent_astar(mapf)
    x = reduce(hcat, all_features_agent(a, solution, mapf) for a in 1:nb_agents(mapf))
    s = std(x; dims=2)
    s[isapprox.(s, 0.0)] .= 1  # columns with zero variance
    x = (x .- mean(x; dims=2)) ./ s
    return x
end
