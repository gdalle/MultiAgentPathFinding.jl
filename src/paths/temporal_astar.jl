function build_astar_path(parents::Dict, s, d, tdep, t)
    path = Int[]
    (τ, v) = (t, d)
    pushfirst!(path, v)
    while τ > tdep
        (τ, v) = parents[τ, v]
        pushfirst!(path, v)
    end
    @assert first(path) == s
    return TimedPath(tdep, path)
end

function temporal_astar(
    g, s, d, tdep, tmax, w, res=Reservation(); heuristic=v -> zero(W), conflict_price=Inf
)
    if conflict_price == Inf
        return temporal_astar_hard(g, s, d, tdep, tmax, w, res; heuristic=heuristic)
    else
        return temporal_astar_soft(
            g, s, d, tdep, tmax, w, res; heuristic=heuristic, conflict_price=conflict_price
        )
    end
end

function temporal_astar_hard(
    g::AbstractGraph{V}, s, d, tdep, tmax, w::AbstractMatrix{W}, res; heuristic=v -> zero(W)
) where {V,W}
    # Init storage
    T = Int
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},W}[])
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    dists = Dict{Tuple{T,V},W}()
    # Add source
    if !is_forbidden_vertex(res, tdep, s) && !isnothing(heuristic(s))
        dists[tdep, s] = zero(W)
        push!(heap, (tdep, s) => heuristic(s))
    end
    # Main loop
    while !isempty(heap)
        (t, u), h_u = pop!(heap)
        Δ_u = dists[t, u]
        if u == d
            timed_path = build_astar_path(parents, s, d, tdep, t)
            return timed_path
        elseif t > tmax
            continue
        else
            for v in outneighbors(g, u)
                isnothing(heuristic(v)) && continue
                is_forbidden_vertex(res, t + 1, v) && continue
                is_forbidden_edge(res, t, u, v) && continue
                Δ_v = get(dists, (t + 1, v), nothing)
                Δ_v_through_u = Δ_u + w[u, v]
                if isnothing(Δ_v) || (Δ_v_through_u < Δ_v)
                    parents[t + 1, v] = (t, u)
                    dists[t + 1, v] = Δ_v_through_u
                    h_v = Δ_v_through_u + heuristic(v)
                    push!(heap, (t + 1, v) => h_v)
                end
            end
        end
    end
    return TimedPath(tdep)
end

function temporal_astar_soft(
    g::AbstractGraph{V},
    s,
    d,
    tdep,
    tmax,
    w::AbstractMatrix{W},
    res;
    heuristic=v -> zero(W),
    conflict_price=zero(W),
) where {V,W}
    # Init storage
    T = Int
    P = promote_type(W, typeof(conflict_price))
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},P}[])
    dists = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    # Add source
    if !isnothing(heuristic(s))
        c_s = is_forbidden_vertex(res, tdep, s)
        dists[tdep, s] = zero(W)
        conflicts[tdep, s] = c_s
        push!(heap, (tdep, s) => conflict_price * c_s + heuristic(s))
    end
    # Main loop
    while !isempty(heap)
        (t, u), priority_u = pop!(heap)
        Δ_u = dists[t, u]
        c_u = conflicts[t, u]
        if u == d
            return build_astar_path(parents, s, d, tdep, t)
        elseif t > tmax
            continue
        else
            for v in outneighbors(g, u)
                isnothing(heuristic(v)) && continue
                c_v = get(conflicts, (t + 1, v), nothing)
                Δ_v = get(dists, (t + 1, v), nothing)
                c_v_after_u = is_forbidden_vertex(res, t + 1, v)
                c_uv = is_forbidden_edge(res, t, u, v)
                c_v_through_u = c_u + c_uv + c_v_after_u
                Δ_v_through_u = Δ_u + w[u, v]
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
    end
    return TimedPath(tdep)
end
