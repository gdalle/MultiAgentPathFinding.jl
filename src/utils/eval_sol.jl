function has_empty_paths(solution)
    return any(length(path) == 0 for path in solution)
end

function is_feasible(solution, mapf::MAPF)
    if has_empty_paths(solution)
        return false
    else
        return !has_conflict(solution, mapf)
    end
end

function flowtime(solution, mapf::MAPF)
    return sum(length(path) for path in solution)
end

is_feasible(::Nothing, ::MAPF) = false
flowtime(::Nothing, ::MAPF) = Inf
