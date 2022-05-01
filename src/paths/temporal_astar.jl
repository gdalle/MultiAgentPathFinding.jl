function temporal_astar(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer;
    edge_indices::Dict,
    edge_weights::Vector{W},
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
) where {V,W}
    # Initialize storage
    came_from = Dict{Tuple{Int,V},Tuple{Int,V}}()
    dist = Dict{Tuple{Int,V},W}()
    open_set = PriorityQueue{Tuple{Int,V},W}()
    # Add first node to storage
    first_node = (t0, s)
    first_node_priority = heuristic(s)
    dist[first_node] = zero(W)
    enqueue!(open_set, first_node, first_node_priority)
    # Initialize path
    path = Tuple{Int,V}[]
    nodes_explored = 0
    # Explore
    while !isempty(open_set)
        (t, v) = dequeue!(open_set)
        nodes_explored += 1
        (t, v) in reservation && continue
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
                (t + 1, w) in reservation && continue
                e_vw = edge_indices[(v, w)]
                weight_vw = edge_weights[e_vw]
                new_dist = dist[(t, v)] + weight_vw
                old_dist = get(dist, (t + 1, w), Inf)
                rest_dist = heuristic(w)
                if rest_dist < typemax(W) && new_dist < old_dist
                    came_from[(t + 1, w)] = (t, v)
                    dist[(t + 1, w)] = new_dist
                    open_set[(t + 1, w)] = new_dist + rest_dist
                end
            end
        end
    end
    @info "Nodes explored $nodes_explored"
    return path
end

function temporal_astar_soft(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer;
    edge_indices::Dict,
    edge_weights::Vector{W},
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
) where {V,W}
    # Initialize storage
    came_from = Dict{Tuple{Int,V},Tuple{Int,V}}()
    dist = Dict{Tuple{Int,V},W}()
    open_set = PriorityQueue{Tuple{Int,V},Tuple{Int,W}}()
    # Add first node to storage
    first_node = (t0, s)
    first_node_priority = (0, heuristic(s))
    dist[first_node] = zero(W)
    enqueue!(open_set, first_node, first_node_priority)
    # Initialize path
    path = Tuple{Int,V}[]
    nodes_explored = 0
    # Explore
    while !isempty(open_set)
        (t, v), (c_v, _) = first(open_set)
        dequeue!(open_set)
        nodes_explored += 1
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
                old_dist = get(dist, (t + 1, w), Inf)
                (old_c, _) = get(open_set, (t + 1, w), (typemax(Int), Inf))
                e_vw = edge_indices[(v, w)]
                weight_vw = edge_weights[e_vw]
                conflict_vw = (t + 1, w) in reservation
                new_dist = dist[(t, v)] + weight_vw
                new_c = c_v + Int(conflict_vw)
                rest_dist = heuristic(w)
                if rest_dist < typemax(W) && (new_c, new_dist) < (old_c, old_dist)
                    came_from[(t + 1, w)] = (t, v)
                    dist[(t + 1, w)] = new_dist
                    open_set[(t + 1, w)] = (new_c, new_dist + rest_dist)
                end
            end
        end
    end
    @info "Nodes explored $nodes_explored"
    return path
end

function temporal_astar_weighted(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer;
    edge_indices::Dict,
    edge_weights::Vector{W},
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
    conflict_cost=1.0,
) where {V,W}
    # Initialize storage
    came_from = Dict{Tuple{Int,V},Tuple{Int,V}}()
    dist = Dict{Tuple{Int,V},W}()
    conflicts = Dict{Tuple{Int,V},Int}()
    open_set = PriorityQueue{Tuple{Int,V},Tuple{Int,W}}()
    # Add first node to storage
    first_node = (t0, s)
    dist[first_node] = zero(W)
    conflicts[fist_node] = 0
    first_node_priority = conflict_cost * 0 + heuristic(s)
    enqueue!(open_set, first_node, first_node_priority)
    # Initialize path
    path = Tuple{Int,V}[]
    nodes_explored = 0
    # Explore
    while !isempty(open_set)
        (t, v) = dequeue!(open_set)
        nodes_explored += 1
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
                old_dist = get(dist, (t + 1, w), Inf)
                old_conflicts = get(conflicts, (t + 1, w), typemax(Int))
                e_vw = edge_indices[(v, w)]
                weight_vw = edge_weights[e_vw]
                conflict_vw = (t + 1, w) in reservation
                new_dist = dist[(t, v)] + weight_vw
                new_conflicts = conflicts[(t, v)] + Int(conflict_vw)
                rest_dist = heuristic(w)
                if (rest_dist < typemax(W)) && (
                    conflict_cost * new_conflicts + new_dist <
                    conflict_cost * old_conflicts + old_dist
                )
                    came_from[(t + 1, w)] = (t, v)
                    dist[(t + 1, w)] = new_dist
                    conflicts[(t + 1, w)] = new_dist
                    open_set[(t + 1, w)] = (new_conflicts, new_dist + rest_dist)
                end
            end
        end
    end
    @info "Nodes explored $nodes_explored"
    return path
end
