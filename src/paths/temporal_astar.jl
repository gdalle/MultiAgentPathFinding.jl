function build_astar_path(came_from::Dict, t0::Integer, s::Integer, t::Integer, d::Integer)
    path = Int[]
    (τ, v) = (t, d)
    pushfirst!(path, v)
    while τ > t0
        (τ, v) = came_from[τ, v]
        pushfirst!(path, v)
    end
    return TimedPath(t0, path)
end

function temporal_astar(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    edge_indices,
    edge_weights_vec::Vector{W};
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
    conflict_price=Inf,
) where {V,W}
    T = Int
    safe_conflict_price = conflict_price * (conflict_price < Inf)

    # Initialize storage
    came_from = Dict{Tuple{T,V},Tuple{T,V}}()
    distance = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    queue = PriorityQueue{Tuple{T,V},Float64}()

    # Add first node to storage
    distance_s = zero(W)
    conflicts_s = is_forbidden_vertex(reservation, t0, s)
    if conflicts_s == 0 || conflict_price < Inf
        priority_s = safe_conflict_price * conflicts_s + heuristic(s)
        distance[t0, s] = distance_s
        conflicts[t0, s] = conflicts_s
        queue[t0, s] = priority_s
    end

    # Explore
    nodes_explored = 0
    while !isempty(queue)
        (t, v) = dequeue!(queue)
        nodes_explored += 1

        if v == d
            return build_astar_path(came_from, t0, s, t, d)
        end

        for w in outneighbors(g, v)
            heur_w = heuristic(w)

            e_vw = edge_indices[v, w]
            weight_vw = edge_weights_vec[e_vw]
            conflict_vw = is_forbidden_vertex(reservation, t + 1, w)

            distance_w = distance[t, v] + weight_vw
            conflicts_w = conflicts[t, v] + conflict_vw

            if conflicts_w == 0 || conflict_price < Inf
                old_distance_w = get(distance, (t + 1, w), Inf)
                old_conflicts_w = get(conflicts, (t + 1, w), typemax(Int) ÷ 2)

                old_cost_w = (safe_conflict_price * old_conflicts_w + old_distance_w)
                cost_w = (safe_conflict_price * conflicts_w + distance_w)

                if cost_w < old_cost_w
                    came_from[t + 1, w] = (t, v)
                    distance[t + 1, w] = distance_w
                    conflicts[t + 1, w] = conflicts_w
                    queue[t + 1, w] = cost_w + heur_w
                end
            end
        end
    end
    return Path()
end
