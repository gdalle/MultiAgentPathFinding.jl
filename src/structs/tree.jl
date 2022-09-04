"""
    ShortestPathTree{T,W}

Storage for the result of Dijkstra's algorithm.

# Fields
- `forward::Bool`
- `parents::Vector{T}`
- `dists::Vector{W}`
"""
struct ShortestPathTree{T,W}
    forward::Bool
    parents::Vector{T}
    dists::Vector{W}
end

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
