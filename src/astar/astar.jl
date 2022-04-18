function temporal_astar(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer;
    edge_weights::AbstractMatrix{W}=weights(g),
    heuristic=v -> 0,
    forbidden_vertices=Set{Tuple{Int,V}}(),
) where {V,W}
    # Initialize storage
    came_from = Dict{Tuple{Int,V},Tuple{Int,V}}()
    dist = Dict{Tuple{Int,V},W}()
    open_set = VectorPriorityQueue{Tuple{Int,V},W}()
    closed = Set{Tuple{Int,V}}()

    # Add first node to storage
    first_node = (t0, s)
    dist[first_node] = zero(W)
    enqueue!(open_set, first_node, heuristic(s))

    # Initialize path
    path = Tuple{Int,V}[]
    nodes_explored = 0

    while !isempty(open_set)
        (t, v) = dequeue!(open_set)
        nodes_explored += 1
        push!(closed, (t, v))

        (t, v) in forbidden_vertices && continue

        if v == d  # optimal path found
            (τ, u) = (t, v)
            pushfirst!(path, (τ, u))
            while τ > t0
                (τ, u) = came_from[(τ, u)]
                pushfirst!(path, (τ, u))
            end
            break

        else  # explore neighbors (possibly including v)
            for w in outneighbors(g, v)
                (t + 1, w) in closed && continue
                (t + 1, w) in forbidden_vertices && continue

                new_dist = dist[(t, v)] + edge_weights[v, w]
                old_dist = get(dist, (t + 1, w), Inf)
                rest_dist = heuristic(w)
                if rest_dist < typemax(W) && new_dist < old_dist
                    came_from[(t + 1, w)] = (t, v)
                    dist[(t + 1, w)] = new_dist
                    enqueue!(open_set, (t + 1, w), new_dist + rest_dist)
                end
            end
        end
    end

    return path
end
