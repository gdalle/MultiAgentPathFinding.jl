"""
    Path

Shortcut for `Vector{Int}`.

A path is represented by the vector of visited vertices, one per time step.
"""
const Path = Vector{Int}

"""
    exists_in_graph(path::Vector{Int}, g::SimpleWeightedGraph)

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
    path_cost(path::Vector{Int}, g::SimpleWeightedGraph)

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
    Solution

Store one path for each agent of a `MAPF`.

# Fields

$(TYPEDFIELDS)
"""
struct Solution
    paths::Vector{Path}
end

function remove_agent(solution::Solution, a::Integer)
    (; paths) = solution
    new_paths = vcat(paths[begin:(a - 1)], paths[(a + 1):end])
    return Solution(new_paths)
end

"""
    sum_of_costs(solution::Solution, mapf::MAPF)

Sum the costs of all the paths in `solution`.

Costs are computed within `mapf` for each agent.
"""
function sum_of_costs(solution::Solution, mapf::MAPF)
    return sum(path_cost(path, mapf.graph) for path in solution.paths)
end

"""
    sum_of_conflicts(solution::Solution, mapf::MAPF)

Sum the number of conflict-inducing moves for each agent.

It doesn't matter how many other agents are involved in the conflict, or whether it is a vertex or a edge conflict (or both).
If a move is infeasible due to a conflict, it counts as one.
"""
function sum_of_conflicts(solution::Solution, mapf::MAPF)
    s = 0
    for (a, path) in enumerate(solution.paths)
        reservation = Reservation(remove_agent(solution, a), mapf)
        for t in eachindex(path)
            vertex_conflict = is_occupied_vertex(reservation, t, path[t])
            edge_conflict = if t < length(path)
                is_occupied_edge(reservation, t, path[t], path[t + 1])
            else
                false
            end
            if vertex_conflict || edge_conflict
                @info "conflict" a t vertex_conflict edge_conflict
            end
            s += vertex_conflict || edge_conflict
        end
        for t in (length(path) + 1):reservation.max_time[]
            s += is_occupied_vertex(reservation, t, path[end])
        end
    end
    return s
end
