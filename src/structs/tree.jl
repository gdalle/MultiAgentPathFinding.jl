"""
$(TYPEDEF)

Storage for the result of Dijkstra's algorithm run backwards.

# Fields

$(TYPEDFIELDS)
"""
struct ShortestPathTree{T,W}
    "successor of each vertex in a shortest path"
    children::Vector{T}
    "distance of each vertex to the arrival "
    dists::Vector{W}
end

"""
$(TYPEDSIGNATURES)

Build a `TimedPath` from a `ShortestPathTree`, going from `dep` to `arr` and starting at time `tdep`.
"""
function build_path_tree(
    spt::ShortestPathTree{T}, dep::Integer, arr::Integer, tdep::Integer
) where {T}
    v = dep
    path = T[v]
    while v != arr
        v = spt.children[v]
        push!(path, v)
    end
    return TimedPath(tdep, path)
end

"""
$(TYPEDSIGNATURES)

Count the edges in a shortest path from `dep` to `arr` based on a `ShortestPathTree`.
"""
function path_length_tree(spt::ShortestPathTree, dep::Integer, arr::Integer)
    l = 0
    v = dep
    while v != arr
        v = spt.children[v]
        l += 1
    end
    return l + 1
end
