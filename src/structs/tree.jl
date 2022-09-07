"""
    ShortestPathTree{T,W}

Storage for the result of Dijkstra's algorithm.

# Fields
- `forward::Bool`: whether Dijkstra was run from the departure or the arrival
- `parents::Vector{T}`: predecessor of each vertex in a shortest path
- `dists::Vector{W}`: distance of each vertex to the arrival (if `forward = true`) or from the departure (if `forward = false`)
"""
struct ShortestPathTree{T,W}
    forward::Bool
    parents::Vector{T}
    dists::Vector{W}
end

"""
    build_path_tree(spt, dep, arr, tdep)

Build a `TimedPath` from a `ShortestPathTree`, going from `dep` to `arr` and starting at time `tdep`.
"""
function build_path_tree(spt::ShortestPathTree{T}, dep, arr, tdep) where {T}
    parents = spt.parents
    if spt.forward
        v = arr
        path = T[v]
        while v != dep
            v = parents[v]
            pushfirst!(path, v)
        end
    else
        v = dep
        path = T[v]
        while v != arr
            v = parents[v]
            push!(path, v)
        end
    end
    return TimedPath(tdep, path)
end

"""
    path_length_tree(spt, dep, arr)

Count the edges in a shortest path from `dep` to `arr` based on a `ShortestPathTree`.
"""
function path_length_tree(spt::ShortestPathTree, dep, arr)
    parents = spt.parents
    l = 0
    if spt.forward
        v = arr
        while v != dep
            v = parents[v]
            l += 1
        end
    else
        v = dep
        while v != arr
            v = parents[v]
            l += 1
        end
    end
    return l + 1
end
