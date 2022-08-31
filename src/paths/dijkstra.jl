"""
    ShortestPathTree{T,W}

Storage for the result of Dijkstra's algorithm.

# Fields
- `forward::Bool`
- `parents::Vector{T}`
- `dists::Vector{W}`
"""
struct ShortestPathTree{T<:Integer,W<:Real}
    forward::Bool
    parents::Vector{T}
    dists::Vector{W}
end

"""
    forward_dijkstra(g, s, w)
"""
function forward_dijkstra(g::AbstractGraph{T}, s::Integer, w::AbstractMatrix{W}) where {T,W}
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{T,W}[])
    parents = zeros(T, nv(g))
    dists = Vector{Union{Nothing,W}}(undef, nv(g))
    # Add source
    dists[s] = zero(W)
    push!(heap, s => zero(W))
    # Main loop
    while !isempty(heap)
        u, Δ_u = pop!(heap)
        if Δ_u <= dists[u]
            dists[u] = Δ_u
            for v in outneighbors(g, u)
                Δ_v = dists[v]
                Δ_v_through_u = Δ_u + w[u, v]
                if isnothing(Δ_v) || (Δ_v_through_u < Δ_v)
                    parents[v] = u
                    dists[v] = Δ_v_through_u
                    push!(heap, v => Δ_v_through_u)
                end
            end
        end
    end
    return ShortestPathTree{T,W}(true, parents, dists)
end

"""
    backward_dijkstra(g, d, w)
"""
function backward_dijkstra(
    g::AbstractGraph{T}, d::Integer, w::AbstractMatrix{W}
) where {T,W}
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{T,W}[])
    parents = zeros(T, nv(g))
    dists = Vector{Union{Nothing,W}}(undef, nv(g))
    # Add source
    dists[d] = zero(W)
    push!(heap, d => zero(W))
    # Main loop
    while !isempty(heap)
        v, Δ_v = pop!(heap)
        if Δ_v <= dists[v]
            dists[v] = Δ_v
            for u in inneighbors(g, v)
                Δ_u = dists[u]
                Δ_u_through_v = w[u, v] + Δ_v
                if isnothing(Δ_u) || (Δ_u_through_v < Δ_u)
                    parents[u] = v
                    dists[u] = Δ_u_through_v
                    push!(heap, u => Δ_u_through_v)
                end
            end
        end
    end
    return ShortestPathTree{T,W}(false, parents, dists)
end

"""
    build_dijkstra_path(shortest_path_tree, t0, s, d)
"""
function build_dijkstra_path(
    spt::ShortestPathTree{T}, t0::Integer, s::Integer, d::Integer
) where {T}
    parents = spt.parents
    if spt.forward
        v = d
        path = T[v]
        while v != s
            v = parents[v]
            if iszero(v)
                return T[]
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
                return T[]
            else
                push!(path, v)
            end
        end
    end
    return TimedPath(t0, path)
end
