Base.@kwdef mutable struct SIPPSNode
    v::Int
    low::Int
    high::Int
    id::Int
    is_goal::Bool = false
    f::Float64
    c::Int
    parent::Union{Nothing,SIPPSNode} = nothing
end

const SafeIntervalTable = Vector{Vector{@NamedTuple{low::Int, high::Int}}}

function same_identity(n1::SIPPSNode, n2::SIPPSNode)
    return n1.v == n2.v && n1.id == n2.id && n1.is_goal == n2.is_goal
end

function build_safe_interval_table(g::AbstractGraph, soft_obstacles::Reservation)
    T = 1
    for (t, v) in soft_obstacles
        T = max(t, T)
    end
    safe_interval_table = [@NamedTuple{low::Int, high::Int}[] for v in 1:nv(g)]
    for v in 1:nv(g)
        t = 1
        while t <= T
            low = t
            status = (t, v) in soft_obstacles
            while t <= T && status == ((t + 1, v) in soft_obstacles)
                t += 1
            end
            push!(safe_interval_table[v], (low=low, high=t+1))
            t += 1
        end
        (; low, high) = safe_interval_table[v][end]
        safe_interval_table[v][end] = (low=low, high=typemax(Int) ÷ 100)
    end
    return safe_interval_table
end

function intervals_intersect((a1, b1)::Tuple{Int,Int}, (a2, b2)::Tuple{Int,Int})
    return (a2 <= a1 < b2) || (a2 <= b1 < b2)
end

function has_soft_obstacles(safe_interval_table::SafeIntervalTable, v::Integer, id::Integer)
    l = length(safe_interval_table[v])
    return (l - id) % 2 == 0  # the last interval is always obstacle-free
end

function extract_path(n::SIPPSNode)
    path = Path()
    while !isnothing(n)
        pushfirst!(path, (n.low, n.v))
        n = n.parent
    end
    return path
end

function compare_with_identical!(X::Vector{SIPPSNode}, n::SIPPSNode)
    indices_to_delete = Int[]
    n_v, n_low, n_high, n_id, n_is_goal, n_c = n.v, n.low, n.high, n.id, n.is_goal, n.c
    for i in eachindex(X)
        q = X[i]
        if n_v == q.v && n_id == q.id && n_is_goal == q.is_goal
            q_low, q_high, q_c = q.low, q.high, q.c
            if q_low <= n_low && q_c <= n_c
                return false, indices_to_delete
            elseif n_low <= q_low && n_c <= q_c
                push!(indices_to_delete, i)
            elseif n_low < q_high && q_low < n_high
                if n_low < q_low
                    n.high = q_low
                else
                    q.high = n_low
                end
            end
        end
    end
    return true, indices_to_delete
end

function insert_node!(Q::PriorityQueue{SIPPSNode}, P::Vector{SIPPSNode}, n::SIPPSNode)
    Q_keep_n, Q_indices_to_delete = compare_with_identical!(keys(Q), n)
    P_keep_n, P_indices_to_delete = compare_with_identical!(P, n)
    deleteat!(Q, Q_indices_to_delete)
    deleteat!(P, P_indices_to_delete)
    if P_keep_n && Q_keep_n
        enqueue!(Q, n, (n.c, n.f))
        return true
    end
end

function expand_node!(
    Q::PriorityQueue{SIPPSNode},
    P::Vector{SIPPSNode},
    n::SIPPSNode,
    g::AbstractGraph,
    heuristic,
    safe_interval_table::SafeIntervalTable,
)
    reachable = Tuple{Int,Int}[]
    for v in outneighbors(g, n.v)
        for id in 1:length(safe_interval_table[v])
            (; low, high) = safe_interval_table[v][id]
            if intervals_intersect((low, high), (n.low + 1, n.high + 1))
                push!(reachable, (v, id))
            end
        end
    end
    for (v, id) in reachable
        (; low, high) = safe_interval_table[v][id]
        n3 = SIPPSNode(;
            v=v,
            low=low,
            high=high,
            id=id,
            is_goal=false,
            f=low + heuristic(v),
            c=n.c + Int(has_soft_obstacles(safe_interval_table, v, id)),
            parent=n,
        )
        insert_node!(Q, P, n3)
    end
end

function SIPPS(
    g::AbstractGraph,
    s::Integer,
    d::Integer,
    t0::Integer;
    heuristic=v -> 0,
    soft_obstacles::Reservation,
)
    safe_interval_table = build_safe_interval_table(g, soft_obstacles)
    root_id = minimum(
        k for (k, (; low, high)) in enumerate(safe_interval_table[s]) if low <= t0 <= high
    )
    root = SIPPSNode(;
        v=s,
        low=t0,
        high=safe_interval_table[s][root_id].high,
        id=root_id,
        is_goal=false,
        f=safe_interval_table[s][root_id].low + heuristic(s),
        c=Int(has_soft_obstacles(safe_interval_table, s, root_id)),
        parent=nothing,
    )

    Q = PriorityQueue{SIPPSNode,Tuple{Int,Float64}}()
    P = SIPPSNode[]
    enqueue!(Q, root, (root.c, root.f))

    while !isempty(Q)
        n = dequeue!(Q)
        if n.is_goal
            return extract_path(n)
        elseif n.v == d
            c_future = count(t > n.low for (t, v) in soft_obstacles if v == d)
            if c_future == 0
                return extract_path(n)
            end
            n2 = SIPPSNode(;
                v=n.v,
                low=n.low,
                high=n.high,
                id=n.id,
                is_goal=true,
                f=n.f,
                c=n.c + c_future,
                parent=n.parent,
            )
            insert_node!(Q, P, n2)
        end
        expand_node!(Q, P, n, g, heuristic, safe_interval_table)
        if !(n in P)
            push!(P, n)
        end
    end

    return Path()
end

function cooperative_SIPPS!(solution::Solution, mapf::MAPF; agents=1:nb_agents(mapf))
    fixed_agents = [a for a = 1:nb_agents(mapf) if !(a in agents)]
    reservation = compute_reservation(solution, mapf; agents=fixed_agents)
    for a in agents
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        path = SIPPS(
            mapf.graph, s, d, t0; heuristic=heuristic, soft_obstacles=reservation
        )
        solution[a] = path
        update_reservation(reservation, path, mapf)
    end
end
