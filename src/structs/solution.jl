const Path = Vector{Int}

"""
$(TYPEDSIGNATURES)

Check that `path` is feasible in the graph `g`, i.e. that all vertices and edges exist.
"""
function exists_in_graph(path::Path, g::SimpleWeightedGraph)
    for t in eachindex(path)
        v = path[t]
        has_vertex(g, v) || return false
    end
    for t in 1:(length(path) - 1)
        u, v = path[t], path[t + 1]
        has_edge(g, u, v) || return false
    end
    return true
end

## Cost

"""
$(TYPEDSIGNATURES)

Sum the costs of all the edges in `path` within `mapf`.
"""
function path_cost(path::Path, g::SimpleWeightedGraph)
    c = zero(weighttype(g))
    for t in 1:(length(path) - 1)
        u, v = path[t], path[t + 1]
        c += get_weight(g, u, v)
    end
    return c
end

"""
$(TYPEDEF)

Store one path for each agent of a `MAPF`.

# Fields

$(TYPEDFIELDS)
"""
struct Solution
    paths::Vector{Path}
end

"""
$(TYPEDSIGNATURES)

Sum the costs of all the paths in `solution`.
Costs are computed within `mapf` for each agent.
"""
function sum_of_costs(solution::Solution, mapf::MAPF)
    return sum(path_cost(path, mapf.graph) for path in solution.paths)
end
