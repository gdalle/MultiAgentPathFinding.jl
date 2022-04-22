struct MyDijkstraState{T<:Integer,W<:Real} <: Graphs.AbstractPathState
    parents::Vector{T}
    dists::Vector{W}
end

function my_dijkstra_shortest_paths(
    g::AbstractGraph{T},
    s::Integer;
    edge_indices::Dict,
    edge_weights::AbstractVector{W},
) where {T<:Integer, W<:Real}
    dists = fill(typemax(W), nv(g))
    parents = zeros(T, nv(g))
    Q = VectorPriorityQueue{T,W}()

    dists[s] = zero(W)
    enqueue!(Q, s, zero(W))

    while !isempty(Q)
        u = dequeue!(Q)
        d_u = dists[u]
        for v in outneighbors(g, u)
            w_uv = edge_weights[edge_indices[u, v]]
            dist_through_u = d_u + w_uv
            if dist_through_u < dists[v]
                dists[v] = dist_through_u
                parents[v] = u
                enqueue!(Q, v, dist_through_u)
            end
        end
    end

    return MyDijkstraState{T,W}(parents, dists)
end
