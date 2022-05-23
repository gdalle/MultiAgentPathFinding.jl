struct ShortestPathTree{T<:Integer,W<:Real}
    forward::Bool
    parents::Vector{T}
    dists::Vector{W}
end

function forward_dijkstra(
    g::AbstractGraph{T},
    s::Integer,
    w::AbstractMatrix{W},
) where {T<:Integer,W<:AbstractFloat}
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{T,W}[])
    dists = fill(typemax(W), nv(g))
    parents = zeros(T, nv(g))
    # Add source
    dists[s] = zero(W)
    push!(heap, s => zero(W))
    # Main loop
    while !isempty(heap)
        u, dist_u = pop!(heap)
        if dist_u <= dists[u]
            dists[u] = dist_u
            for v in outneighbors(g, u)
                dist_v = dist_u + w[u, v]
                if dist_v < dists[v]
                    parents[v] = u
                    dists[v] = dist_v
                    push!(heap, v => dist_v)
                end
            end
        end
    end
    return ShortestPathTree{T,W}(true, parents, dists)
end

function backward_dijkstra(
    g::AbstractGraph{T},
    d::Integer,
    w::AbstractMatrix{W},
) where {T<:Integer,W<:AbstractFloat}
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{T,W}[])
    dists = fill(typemax(W), nv(g))
    parents = zeros(T, nv(g))
    # Add source
    dists[d] = zero(W)
    push!(heap, d => zero(W))
    # Main loop
    while !isempty(heap)
        v, dist_v = pop!(heap)
        if dist_v <= dists[v]
            dists[v] = dist_v
            for u in inneighbors(g, v)
                dist_u = w[u, v] + dist_v
                if dist_u < dists[u]
                    parents[u] = v
                    dists[u] = dist_u
                    push!(heap, u => dist_u)
                end
            end
        end
    end
    return ShortestPathTree{T,W}(false, parents, dists)
end

function build_dijkstra_path(spt::ShortestPathTree, t0::Integer, s::Integer, d::Integer)
    parents = spt.parents
    if spt.forward
        v = d
        path = [v]
        while v != s
            v = parents[v]
            if v == zero(v)
                return typeof(v)[]
            else
                pushfirst!(path, v)
            end
        end
    else
        v = s
        path = [v]
        while v != d
            v = parents[v]
            if v == zero(v)
                return typeof(v)[]
            else
                push!(path, v)
            end
        end
    end
    return TimedPath(t0, path)
end
