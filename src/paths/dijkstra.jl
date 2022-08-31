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
    return ShortestPathTree{T,Union{Nothing,W}}(true, parents, dists)
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
    return ShortestPathTree{T,Union{Nothing,W}}(false, parents, dists)
end
