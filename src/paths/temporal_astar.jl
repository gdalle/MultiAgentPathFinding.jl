function build_path_astar(parents::Dict, arr, tarr;)
    path = Int[]
    (t, v) = (tarr, arr)
    pushfirst!(path, v)
    while haskey(parents, (t, v))
        (t, v) = parents[t, v]
        pushfirst!(path, v)
    end
    return TimedPath(t, path)
end

function temporal_astar(
    g,
    w::AbstractMatrix{W};
    dep,
    arr,
    tdep,
    tmax,
    res=Reservation(),
    heuristic=v -> zero(W),
    conflict_price=Inf,
) where {W}
    if conflict_price == Inf
        return temporal_astar_hard(
            g, w; dep=dep, arr=arr, tdep=tdep, tmax=tmax, res=res, heuristic=heuristic
        )
    else
        return temporal_astar_soft(
            g,
            w;
            dep=dep,
            arr=arr,
            tdep=tdep,
            tmax=tmax,
            res=res,
            heuristic=heuristic,
            conflict_price=conflict_price,
        )
    end
end

function temporal_astar_hard(
    g::AbstractGraph{V}, w::AbstractMatrix{W}; dep, arr, tdep, tmax, res, heuristic
) where {V,W}
    # Init storage
    T = Int
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},W}[])
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    dists = Dict{Tuple{T,V},W}()
    # Add source
    if !is_forbidden_vertex(res, tdep, dep)
        dists[tdep, dep] = zero(W)
        push!(heap, (tdep, dep) => heuristic(dep))
    end
    # Main loop
    while !isempty(heap)
        (t, u), priority_u = pop!(heap)
        Δ_u = dists[t, u]
        if u == arr
            timed_path = build_path_astar(parents, arr, t)
            if t == tmax + 1
                return remove_arrival_vertex(timed_path)
            else
                return timed_path
            end
        elseif t == tmax
            v = arr
            Δ_v = get(dists, (t + 1, v), nothing)
            Δ_v_through_u = Δ_u + heuristic(u)
            if isnothing(Δ_v) || (Δ_v_through_u < Δ_v)
                parents[t + 1, v] = (t, u)
                dists[t + 1, v] = Δ_v_through_u
                h_v = Δ_v_through_u + heuristic(v)
                push!(heap, (t + 1, v) => h_v)
            end
        elseif t < tmax
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
    w::AbstractMatrix{W};
    dep,
    arr,
    tdep,
    tmax,
    res,
    heuristic,
    conflict_price,
) where {V,W}
    # Init storage
    T = Int
    P = promote_type(W, typeof(conflict_price))
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},P}[])
    dists = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    # Add source
    c_dep = is_forbidden_vertex(res, tdep, dep)
    dists[tdep, dep] = zero(W)
    conflicts[tdep, dep] = c_dep
    push!(heap, (tdep, dep) => conflict_price * c_dep + heuristic(dep))
    # Main loop
    while !isempty(heap)
        (t, u), priority_u = pop!(heap)
        Δ_u = dists[t, u]
        c_u = conflicts[t, u]
        if u == arr
            timed_path = build_path_astar(parents, arr, t)
            if t == tmax + 1
                return remove_arrival_vertex(timed_path)
            else
                return timed_path
            end
        elseif t == tmax
            v = arr
            c_v = get(conflicts, (t + 1, v), nothing)
            Δ_v = get(dists, (t + 1, v), nothing)
            c_v_after_u = is_forbidden_vertex(res, t + 1, v)
            c_uv = is_forbidden_edge(res, t, u, v)
            c_v_through_u = c_u + c_uv + c_v_after_u
            Δ_v_through_u = Δ_u + heuristic(u)
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
        elseif t < tmax
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
