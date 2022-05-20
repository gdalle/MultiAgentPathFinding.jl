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

function custom_dijkstra(
    g::AbstractGraph{T},
    s::Integer;
    edge_indices,
    edge_weights::AbstractVector{W},
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
            w_uv = edge_weights[e_uv]
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
