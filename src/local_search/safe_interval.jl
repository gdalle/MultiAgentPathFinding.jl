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

function same_identity(n1, n2)
    return n1.v == n2.v && n1.id == n2.id && n1.is_goal == n2.is_goal
end

function build_safe_interval_table(g, soft_obstacles)
    T = 1
    for (t, v) in soft_obstacles
        T = max(t, T)
    end
    𝓣 = [@NamedTuple{low::Int, high::Int}[] for v in 1:nv(g)]
    for v in 1:nv(g)
        t = 1
        while t <= T
            low = t
            status = (t, v) in soft_obstacles
            while t <= T && status == ((t + 1, v) in soft_obstacles)
                t += 1
            end
            push!(𝓣[v], (low=low, high=t))
            t += 1
        end
        @unpack low, high = 𝓣[v][end]
        𝓣[v][end] = (low=low, high=typemax(Int) ÷ 100)
    end
    return 𝓣
end

function intervals_intersect((a1, b1), (a2, b2))
    return a2 <= a1 <= b2 || a2 <= b1 <= b2
end

function has_soft_obstacles(𝓣, v, id)
    l = length(𝓣[v])
    return (l - id) % 2 == 0  # the last interval is always obstacle-free
end

function extract_path(n)
    path = Path()
    while !isnothing(n)
        pushfirst!(path, (n.low, n.v))
        n = n.parent
    end
    return path
end

function insert_node!(Q, P, n)
    Q_indices_to_delete = Int[]
    for (i, q) in enumerate(keys(Q))
        if same_identity(n, q)
            if q.low <= n.low && q.c <= n.c
                return false
            elseif n.low <= q.low && n.c <= q.c
                pushfirst!(Q_indices_to_delete, i)
            elseif n.low < q.high && q.low < n.high
                if n.low < q.low
                    n.high = q.low
                else
                    q.high = n.low
                end
            end
        end
    end
    for i in Q_indices_to_delete
        deleteat!(Q, i)
    end
    P_indices_to_delete = Int[]
    for (i, q) in enumerate(P)
        if same_identity(n, q)
            if q.low <= n.low && q.c <= n.c
                return false
            elseif n.low <= q.low && n.c <= q.c
                pushfirst!(P_indices_to_delete, i)
            elseif n.low < q.high && q.low < n.high
                if n.low < q.low
                    n.high = q.low
                else
                    q.high = n.low
                end
            end
        end
    end
    for i in P_indices_to_delete
        deleteat!(P, i)
    end
    enqueue!(Q, n, (n.c, n.f))
    return true
end

function expand_node!(Q, P, n, g, heuristic, 𝓣)
    𝓘 = Set{Tuple{Int,Int}}()
    for v in outneighbors(g, n.v)
        for id in 1:length(𝓣[v])
            @unpack low, high = 𝓣[v][id]
            if intervals_intersect((low, high), (n.low + 1, n.high + 1))
                push!(𝓘, (v, id))
            end
        end
    end
    # for id = 1:length(𝓣[n.v])
    #     if 𝓣[n.v][id].low == n.high
    #         push!(𝓘, (n.v, id))
    #     end
    # end
    for (v, id) in 𝓘
        @unpack low, high = 𝓣[v][id]
        n3 = SIPPSNode(;
            v=v,
            low=n.low + 1,
            high=high,
            id=id,
            is_goal=false,
            f=n.low + 1 + heuristic(v),
            c=n.c + Int(has_soft_obstacles(𝓣, v, id)),
            parent=n,
        )
        insert_node!(Q, P, n3)
    end
end

function SIPPS(
    g::AbstractGraph{V},
    s::Integer,
    d::Integer,
    t0::Integer;
    edge_weights::AbstractMatrix{W}=weights(g),
    heuristic=v -> 0,
    soft_obstacles=Set{Tuple{Int,V}}(),
) where {V,W}
    T = 0
    for (t, v) in soft_obstacles
        T = max(t, T)
    end
    𝓣 = build_safe_interval_table(g, soft_obstacles)

    root_id = minimum(k for (k, (low, high)) in enumerate(𝓣[s]) if low <= t0 <= high)
    root = SIPPSNode(;
        v=s,
        low=t0,
        high=𝓣[s][root_id].high,
        id=root_id,
        is_goal=false,
        f=𝓣[s][root_id].low + heuristic(s),
        c=Int(has_soft_obstacles(𝓣, s, root_id)),
        parent=nothing,
    )

    # Q = PriorityQueue{SIPPSNode,Tuple{Int,Float64}}()
    Q = MyPriorityQueue{SIPPSNode,Tuple{Int,Float64}}()
    # P = Set{SIPPSNode}()
    P = SIPPSNode[]
    enqueue!(Q, root, (root.c, root.f))

    while !isempty(Q)
        n = dequeue!(Q)
        if n.is_goal
            return extract_path(n)
        elseif n.v == d
            c_future = count((t, d) in soft_obstacles for t in (n.low + 1):T)
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
        expand_node!(Q, P, n, g, heuristic, 𝓣)
        if !(n in P)
            push!(P, n)
        end
    end

    return Path()
end

function cooperative_SIPPS!(solution::Solution, agents, mapf::MAPF)
    forbidden_vertices = compute_forbidden_vertices(solution, mapf)
    graph, edge_weights = mapf.graph, mapf.edge_weights
    for a in agents
        s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
        dist = mapf.distances_to_destinations[d]
        heuristic(v) = dist[v]
        path = SIPPS(
            graph,
            s,
            d,
            t0;
            edge_weights=edge_weights,
            heuristic=heuristic,
            soft_obstacles=forbidden_vertices,
        )
        solution[a] = path
        update_forbidden_vertices!(forbidden_vertices, path, mapf)
    end
end
