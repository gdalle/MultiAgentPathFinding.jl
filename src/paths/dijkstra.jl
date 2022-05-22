struct ShortestPathTree{T<:Integer,W<:Real}
    forward::Bool
    parents::Vector{T}
    dists::Vector{W}
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

function forward_dijkstra(
    g::AbstractGraph{T},
    s::Integer,
    edge_indices,
    edge_weights_vec::AbstractVector{W},
) where {T<:Integer,W<:AbstractFloat}
    queue = PriorityQueue{T,W}()
    dists = fill(typemax(W), nv(g))
    parents = zeros(T, nv(g))
    dists[s] = zero(W)
    queue[s] = zero(W)
    while !isempty(queue)
        u, d_u = dequeue_pair!(queue)
        dists[u] = d_u
        for v in outneighbors(g, u)
            e_uv = edge_indices[u, v]
            w_uv = edge_weights_vec[e_uv]
            dist_through_u = d_u + w_uv
            if dist_through_u < dists[v]
                dists[v] = dist_through_u
                queue[v] = dist_through_u
                parents[v] = u
            end
        end
    end
    return ShortestPathTree{T,W}(true, parents, dists)
end

function backward_dijkstra(
    g::AbstractGraph{T},
    d::Integer,
    edge_indices,
    edge_weights_vec::AbstractVector{W},
) where {T<:Integer,W<:AbstractFloat}
    queue = PriorityQueue{T,W}()
    dists = fill(typemax(W), nv(g))
    parents = zeros(T, nv(g))
    dists[d] = zero(W)
    queue[d] = zero(W)
    while !isempty(queue)
        v, d_v = dequeue_pair!(queue)
        dists[v] = d_v
        for u in inneighbors(g, v)
            e_uv = edge_indices[u, v]
            w_uv = edge_weights_vec[e_uv]
            dist_through_v = w_uv + d_v
            if dist_through_v < dists[u]
                dists[u] = dist_through_v
                queue[u] = dist_through_v
                parents[u] = v
            end
        end
    end
    return ShortestPathTree{T,W}(false, parents, dists)
end
