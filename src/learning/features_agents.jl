function constant_features_agent(a::Integer, mapf::MAPF)
    t0 = mapf.starting_times[a]
    return Float64[a, t0]
end

function path_features_agent(a::Integer, solution::Solution, mapf::MAPF)
    (; g) = mapf
    path = solution[a]
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

function agent_embedding(a::Integer, solution::Solution, mapf::MAPF)
    return vcat(
        constant_features_agent(a, mapf),
        path_features_agent(a, solution, mapf),
        conflict_features_agent(a, solution, mapf),
    )
end

function all_agents_embedding(solution::Solution, mapf::MAPF)
    x = reduce(hcat, all_features_agent(a, solution, mapf) for a in 1:nb_agents(mapf))
    return x
end
