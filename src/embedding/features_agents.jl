function mission_features_agent(a::Integer, mapf::MAPF)
    t0 = mapf.starting_times[a]
    return (Float64(a), Float64(t0))
end

function path_features_agent(a::Integer, solution::Solution, mapf::MAPF)
    (; g) = mapf
    timed_path = solution[a]
    (; t0, path) = timed_path
    duration = length(path)
    weight = path_weight(timed_path, mapf)
    mean_outdeg = mean(outdegree(g, v) for v in path)
    mean_indeg = mean(indegree(g, v) for v in path)
    return (Float64(duration), Float64(weight), Float64(mean_indeg), Float64(mean_outdeg))
end

function conflict_features_agent(a::Integer, solution::Solution, mapf::MAPF)
    A = nb_agents(mapf)
    conflicts0 = count_conflicts(a, solution, mapf; tol=0)
    conflicts1 = count_conflicts(a, solution, mapf; tol=1)
    conflicts2 = count_conflicts(a, solution, mapf; tol=2)
    conflicts3 = count_conflicts(a, solution, mapf; tol=3)
    return (
        Float64(conflicts0), Float64(conflicts1), Float64(conflicts2), Float64(conflicts3)
    )
end
