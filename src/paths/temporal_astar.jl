function build_astar_path(came_from::Dict, t::Integer, v::Integer, t0::Integer)
    path = Path()
    (τ, u) = (t, v)
    pushfirst!(path, (τ, u))
    while τ > t0
        (τ, u) = came_from[(τ, u)]
        pushfirst!(path, (τ, u))
    end
    return path
end

function temporal_astar(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer;
    edge_indices::Dict,
    edge_weights::Vector{W},
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
    conflict_price=Inf,
) where {V,W}
    T = Int

    # Initialize storage
    came_from = Dict{Tuple{T,V},Tuple{T,V}}()
    dist = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    open_set = PriorityQueue{Tuple{T,V},Float64}()

    # Add first node to storage
    first_node = (t0, s)
    first_node_dist = zero(W)
    first_node_conflicts = Int(first_node in reservation)
    first_node_priority = (
        conflict_price * (conflict_price < Inf) * first_node_conflicts + heuristic(s)
    )
    dist[first_node] = first_node_dist
    conflicts[first_node] = first_node_conflicts
    enqueue!(open_set, first_node, first_node_priority)

    # Explore
    nodes_explored = 0
    while !isempty(open_set)
        (t, v) = dequeue!(open_set)
        nodes_explored += 1
        conflict_price == Inf && (t, v) in reservation && continue
        if v == d  # optimal path found
            return build_astar_path(came_from, t, v, t0)
        else  # explore neighbors (possibly including v)
            for w in outneighbors(g, v)
                rest_dist = heuristic(w)
                rest_dist == typemax(W) && continue

                e_vw = edge_indices[(v, w)]
                weight_vw = edge_weights[e_vw]
                conflict_vw = Int((t + 1, w) in reservation)

                old_dist = get(dist, (t + 1, w), Inf)
                old_conflicts = get(conflicts, (t + 1, w), typemax(Int))

                new_dist = dist[(t, v)] + weight_vw
                new_conflicts = conflicts[(t, v)] + conflict_vw

                old_cost = (
                    conflict_price * (conflict_price < Inf) * old_conflicts + old_dist
                )
                new_cost = (
                    conflict_price * (conflict_price < Inf) * new_conflicts + new_dist
                )

                if new_cost < old_cost
                    came_from[(t + 1, w)] = (t, v)
                    dist[(t + 1, w)] = new_dist
                    conflicts[(t + 1, w)] = new_conflicts
                    open_set[(t + 1, w)] = new_cost + rest_dist
                end
            end
        end
    end
    return Path()
end
