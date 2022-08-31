"""
    build_astar_path(parents, t0, s, tf, d)
"""
function build_astar_path(parents::Dict, t0::Integer, s::Integer, tf::Integer, d::Integer)
    path = Int[]
    (τ, v) = (tf, d)
    pushfirst!(path, v)
    while τ > t0
        (τ, v) = parents[τ, v]
        pushfirst!(path, v)
    end
    return TimedPath(t0, path)
end

"""
    temporal_astar(g, s, d, t0, w[, res; heuristic, conflict_price])
"""
function temporal_astar(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    w::AbstractMatrix{W},
    res::Reservation=Reservation();
    heuristic::Function=v -> 0.0,
    conflict_price::Float64=Inf,
) where {V,W}
    if conflict_price == Inf
        return temporal_astar_hard(g, s, d, t0, w, res; heuristic=heuristic)
    else
        return temporal_astar_soft(
            g, s, d, t0, w, res; heuristic=heuristic, conflict_price=conflict_price
        )
    end
end

"""
    temporal_astar_hard(g, s, d, t0, w[, res; heuristic])
"""
function temporal_astar_hard(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    w::AbstractMatrix{W},
    res::Reservation;
    heuristic=v -> 0.0,
) where {V,W}
    T = Int
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},W}[])
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    dists = Dict{Tuple{T,V},W}()
    # Add source
    if !is_forbidden_vertex(res, t0, s)
        dists[t0, s] = zero(W)
        push!(heap, (t0, s) => heuristic(s))
    end
    # Main loop
    while !isempty(heap)
        (t, u), h_u = pop!(heap)
        if u == d
            return build_astar_path(parents, t0, s, t, d)
        else
            for v in outneighbors(g, u)
                is_forbidden_edge(res, t, u, v) && continue
                is_forbidden_vertex(res, t + 1, v) && continue
                Δ_v = get(dists, (t + 1, v), nothing)
                Δ_v_through_u = dists[t, u] + w[u, v]
                if isnothing(Δ_v) || (Δ_v_through_u < Δ_v)
                    parents[t + 1, v] = (t, u)
                    dists[t + 1, v] = Δ_v_through_u
                    h_v = Δ_v_through_u + heuristic(v)
                    push!(heap, (t + 1, v) => h_v)
                end
            end
        end
    end
    return TimedPath(t0, Int[])
end

"""
    temporal_astar_soft(g, s, d, t0, w[, res; heuristic, conflict_price])
"""
function temporal_astar_soft(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer,
    w::AbstractMatrix{W},
    res::Reservation;
    heuristic=v -> 0.0,
    conflict_price=0.0,
) where {V,W}
    T = Int
    # Init storage
    P = promote_type(W, typeof(conflict_price))
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},P}[])
    dists = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    # Add source
    c_s = is_forbidden_vertex(res, t0, s)
    dists[t0, s] = zero(W)
    conflicts[t0, s] = c_s
    push!(heap, (t0, s) => conflict_price * c_s + heuristic(s))
    # Main loop
    while !isempty(heap)
        (t, u), priority_u = pop!(heap)
        if u == d
            return build_astar_path(parents, t0, s, t, d)
        end
        for v in outneighbors(g, u)
            c_v = get(conflicts, (t + 1, v), nothing)
            Δ_v = get(dists, (t + 1, v), nothing)
            c_v_through_u = (
                conflicts[t, u] +
                is_forbidden_edge(res, t, u, v) +
                is_forbidden_vertex(res, t + 1, v)
            )
            Δ_v_through_u = dists[t, u] + w[u, v]
            cost_v_through_u = conflict_price * c_v_through_u + Δ_v_through_u
            if (
                isnothing(c_v) ||
                isnothing(Δ_v) ||
                cost_v_through_u < conflict_price * c_v + Δ_v
            )
                parents[t + 1, v] = (t, u)
                dists[t + 1, v] = Δ_v_through_u
                conflicts[t + 1, v] = c_v_through_u
                priority_v = cost_v_through_u + heuristic(v)
                push!(heap, (t + 1, v) => priority_v)
            end
        end
    end
    return TimedPath(t0, Int[])
end
