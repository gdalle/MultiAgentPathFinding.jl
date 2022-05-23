function temporal_astar(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    edge_indices::Dict,
    edge_weights_vec::AbstractVector{W};
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
    conflict_price=Inf,
) where {V,W<:AbstractFloat}
    if conflict_price == Inf
        return temporal_astar_hard(
            g,
            s,
            d,
            t0,
            edge_indices,
            edge_weights_vec;
            heuristic=heuristic,
            reservation=reservation,
        )
    else
        return temporal_astar_soft(
            g,
            s,
            d,
            t0,
            edge_indices,
            edge_weights_vec;
            heuristic=heuristic,
            reservation=reservation,
            conflict_price=conflict_price
        )
    end
end

function temporal_astar_hard(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    edge_indices::Dict,
    edge_weights_vec::AbstractVector{W};
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
) where {V,W}
    T = Int
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},W}[])
    dists = Dict{Tuple{T,V},W}()
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    # Add source
    if !is_forbidden_vertex(reservation, t0, s)
        dists[t0, s] = zero(W)
        push!(heap, (t0, s) => heuristic(s))
    end
    # Main loop
    while !isempty(heap)
        (t, u), _ = pop!(heap)
        if u == d
            return build_astar_path(parents, t0, s, t, d)
        end
        for v in outneighbors(g, u)
            is_forbidden_vertex(reservation, t + 1, v) && continue
            e_uv = edge_indices[u, v]
            w_uv = edge_weights_vec[e_uv]
            dist_v = dists[t, u] + w_uv
            old_dist_v = get(dists, (t + 1, v), typemax(W))
            if dist_v < old_dist_v
                parents[t + 1, v] = (t, u)
                dists[t + 1, v] = dist_v
                push!(heap, (t + 1, v) => dist_v + heuristic(v))
            end
        end
    end
    return TimedPath(t0, Int[])
end

function temporal_astar_soft(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    edge_indices,
    edge_weights_vec::AbstractVector{W};
    heuristic=v -> 0.0,
    reservation::Reservation=Reservation(),
    conflict_price=0.0,
) where {V,W}
    T = Int
    conflict_price = float(conflict_price)
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},W}[])
    dists = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    # Add source
    dists[t0, s] = zero(W)
    conflicts_s = is_forbidden_vertex(reservation, t0, s)
    conflicts[t0, s] = conflicts_s
    push!(heap, (t0, s) => conflict_price * conflicts_s + heuristic(s))
    # Main loop
    while !isempty(heap)
        (t, u), _ = pop!(heap)
        if u == d
            return build_astar_path(parents, t0, s, t, d)
        end
        for v in outneighbors(g, u)
            e_uv = edge_indices[u, v]
            w_uv = edge_weights_vec[e_uv]
            dist_v = dists[t, u] + w_uv
            conflicts_v = conflicts[t, u] + is_forbidden_vertex(reservation, t + 1, v)
            old_dist_v = get(dists, (t + 1, v), typemax(W))
            old_conflicts_v = get(conflicts, (t + 1, v), typemax(Int) ÷ 10)
            cost_v = conflict_price * conflicts_v + dist_v
            old_cost_v = conflict_price * old_conflicts_v + old_dist_v
            if cost_v < old_cost_v
                parents[t + 1, v] = (t, u)
                dists[t + 1, v] = dist_v
                conflicts[t + 1, v] = conflicts_v
                push!(heap, (t + 1, v) => cost_v + heuristic(v))
            end
        end
    end
    return TimedPath(t0, Int[])
end

function build_astar_path(parents::Dict, t0::Integer, s::Integer, t::Integer, d::Integer)
    path = Int[]
    (τ, v) = (t, d)
    pushfirst!(path, v)
    while τ > t0
        (τ, v) = parents[τ, v]
        pushfirst!(path, v)
    end
    return TimedPath(t0, path)
end
