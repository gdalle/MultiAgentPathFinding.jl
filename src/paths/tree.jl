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

function build_timed_path(spt::ShortestPathTree{T}, s, d, tdep) where {T}
    parents = spt.parents
    if spt.forward
        v = d
        path = T[v]
        while v != s
            v = parents[v]
            if iszero(v)
                return TimedPath(tdep, T[])
            else
                pushfirst!(path, v)
            end
        end
    else
        v = s
        path = T[v]
        while v != d
            v = parents[v]
            if iszero(v)
                return TimedPath(tdep, T[])
            else
                push!(path, v)
            end
        end
    end
    return TimedPath(tdep, path)
end
