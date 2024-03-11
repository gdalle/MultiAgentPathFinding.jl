"""
$(TYPEDSIGNATURES)

Build a [`TimedPath`](@ref) from a dictionary of temporal `parents`, going backward from `arr` which was reached at `tarr`.
"""
function build_path_astar(parents::Dict, arr::Integer, tarr::Integer)
    path = Int[]
    (t, v) = (tarr, arr)
    pushfirst!(path, v)
    while haskey(parents, (t, v))
        (t, v) = parents[t, v]
        pushfirst!(path, v)
    end
    return TimedPath(t, path)
end

"""
$(TYPEDSIGNATURES)

Apply temporal A* to graph `g`, with specified edge costs.

# Keyword arguments

- `a`: agent
- `dep`: departure vertex
- `arr`: arrival vertex
- `tdep`: departure time
- `reservation`: reservation indicating occupied vertices and edges at various times
- `heuristic`: indexable giving an underestimate of the remaining distance to `arr`
- `max_nodes`: maximum number of nodes in the search tree, defaults to `nv(g)^3`
"""
function temporal_astar(
    g::AbstractGraph{V},
    edge_costs;
    a::Integer,
    dep::Integer,
    arr::Integer,
    tdep::Integer,
    reservation::Reservation,
    heuristic,
    max_nodes::Integer=nv(g)^3,
) where {V}
    W = eltype(edge_costs)
    timed_path = TimedPath(tdep)
    # Init storage
    T = Int
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},W}[])
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    dists = Dict{Tuple{T,V},W}()
    # Add source
    if !is_occupied_vertex(reservation, tdep, dep)
        dists[tdep, dep] = zero(W)
        push!(heap, (tdep, dep) => heuristic[dep])
    end
    # Main loop
    nodes_explored = 0
    while !isempty(heap)
        nodes_explored += 1
        if nodes_explored > max_nodes
            error("Temporal A* does not seem to converge")
        end
        (t, u), priority_u = pop!(heap)
        Δ_u = dists[t, u]
        if u == arr
            timed_path = build_path_astar(parents, arr, t)
            break
        else
            for v in outneighbors(g, u)
                isnothing(heuristic[v]) && continue
                is_occupied_vertex(reservation, t + 1, v) && continue
                is_occupied_edge(reservation, t, u, v) && continue
                Δ_v = get(dists, (t + 1, v), nothing)
                Δ_v_through_u = Δ_u + edge_cost(edge_costs, u, v, a, t)
                if isnothing(Δ_v) || (Δ_v_through_u < Δ_v)
                    parents[t + 1, v] = (t, u)
                    dists[t + 1, v] = Δ_v_through_u
                    h_v = Δ_v_through_u + heuristic[v]
                    push!(heap, (t + 1, v) => h_v)
                end
            end
        end
    end
    stats = Dict(:nodes_explored => nodes_explored)
    return timed_path, stats
end

"""
$(TYPEDSIGNATURES)

Apply a bi-objective variant of temporal A* to graph `g` with specified `edge_costs`.

The objective is to minimize a weighted combination of (1) the number of conflicts and (2) the path cost.

# Keyword arguments

- `a`, `dep`, `arr`, `tdep`, `reservation`, `heuristic`, `max_nodes`: see `temporal_astar`.
- `conflict_price`: price given to the number of conflicts in the objective
"""
function temporal_astar_soft(
    g::AbstractGraph{V},
    edge_costs;
    a::Integer,
    dep::Integer,
    arr::Integer,
    tdep::Integer,
    reservation::Reservation,
    heuristic::AbstractVector,
    conflict_price::Real,
    max_nodes::Integer=nv(g)^3,
) where {V}
    W = eltype(edge_costs)
    timed_path = TimedPath(tdep)
    # Init storage
    T = Int
    P = promote_type(W, typeof(conflict_price))
    heap = BinaryHeap(Base.By(last), Pair{Tuple{T,V},P}[])
    dists = Dict{Tuple{T,V},W}()
    conflicts = Dict{Tuple{T,V},Int}()
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    # Add source
    c_dep = is_occupied_vertex(reservation, tdep, dep)
    dists[tdep, dep] = zero(W)
    conflicts[tdep, dep] = c_dep
    push!(heap, (tdep, dep) => conflict_price * c_dep + heuristic[dep])
    # Main loop
    nodes_explored = 0
    while !isempty(heap)
        nodes_explored += 1
        if nodes_explored > max_nodes
            error("Temporal A* does not seem to converge")
        end
        (t, u), priority_u = pop!(heap)
        Δ_u = dists[t, u]
        c_u = conflicts[t, u]
        if u == arr
            timed_path = build_path_astar(parents, arr, t)
            break
        else
            for v in outneighbors(g, u)
                isnothing(heuristic[v]) && continue
                c_v = get(conflicts, (t + 1, v), nothing)
                Δ_v = get(dists, (t + 1, v), nothing)
                c_v_after_u = is_occupied_vertex(reservation, t + 1, v)
                c_uv = is_occupied_edge(reservation, t, u, v)
                c_v_through_u = c_u + c_uv + c_v_after_u
                Δ_v_through_u = Δ_u + edge_cost(edge_costs, u, v, a, t)
                cost_v_through_u = conflict_price * c_v_through_u + Δ_v_through_u
                if (
                    isnothing(c_v) ||
                    isnothing(Δ_v) ||
                    cost_v_through_u < conflict_price * c_v + Δ_v
                )
                    parents[t + 1, v] = (t, u)
                    dists[t + 1, v] = Δ_v_through_u
                    conflicts[t + 1, v] = c_v_through_u
                    priority_v = cost_v_through_u + heuristic[v]
                    push!(heap, (t + 1, v) => priority_v)
                end
            end
        end
    end
    stats = Dict(:nodes_explored => nodes_explored)
    return timed_path, stats
end
