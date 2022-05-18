struct ShortestPathTree{T<:Integer,W<:Real}
    parents::Vector{T}
    dists::Vector{W}
end

function build_dijkstra_path_rev(spt::ShortestPathTree, t0::Integer, s::Integer, d::Integer)
    parents = spt.parents
    t, v = t0, s
    path = [(t, v)]
    while v != d
        v = parents[v]
        if v == zero(v)
            return Path()
        else
            t += 1
            push!(path, (t, v))
        end
    end
    return path
end

function my_dijkstra!(
    queue::Q,
    g::AbstractGraph{T},
    s::Integer;
    edge_indices::Dict,
    edge_weights::AbstractVector{W},
) where {Q,T<:Integer,W<:AbstractFloat}
    dists = fill(typemax(W), nv(g))
    parents = zeros(T, nv(g))
    dists[s] = zero(W)
    enqueue!(queue, s, zero(W))
    while !isempty(queue)
        u = dequeue!(queue)
        d_u = dists[u]
        for v in outneighbors(g, u)
            i_uv = edge_indices[u, v]
            w_uv = edge_weights[i_uv]
            dist_through_u = d_u + w_uv
            if dist_through_u < dists[v]
                dists[v] = dist_through_u
                parents[v] = u
                queue[v] = dist_through_u
            end
        end
    end
    return ShortestPathTree{T,W}(parents, dists)
end

function my_dijkstra(
    g::AbstractGraph{T}, s::Integer; edge_indices::Dict, edge_weights::AbstractVector{W}
) where {T<:Integer,W<:AbstractFloat}
    queue = PriorityQueue{T,W}()
    return my_dijkstra!(queue, g, s; edge_indices=edge_indices, edge_weights=edge_weights)
end
