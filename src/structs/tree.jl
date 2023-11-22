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
    build_path_tree(spt, dep, arr, tdep)

Build a `TimedPath` from a `ShortestPathTree`, going from `dep` to `arr` and starting at time `tdep`.
"""
function build_path_tree(spt::ShortestPathTree{T}, dep, arr, tdep) where {T}
    v = dep
    path = T[v]
    while v != arr
        v = spt.children[v]
        push!(path, v)
    end
    return TimedPath(tdep, path)
end

"""
    path_length_tree(spt, dep, arr)

Count the edges in a shortest path from `dep` to `arr` based on a `ShortestPathTree`.
"""
function path_length_tree(spt::ShortestPathTree, dep, arr)
    l = 0
    v = dep
    while v != arr
        v = spt.children[v]
        l += 1
    end
    return l + 1
end
