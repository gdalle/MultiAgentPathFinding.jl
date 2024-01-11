"""
    backward_dijkstra(g, w; arr)

Run Dijkstra's algorithm backward from an arrival vertex, with specified edge weights.

Returns a `ShortestPathTree` where distances can be `nothing`.
"""
function backward_dijkstra(g::AbstractGraph{T}, w::AbstractMatrix{W}; arr) where {T,W}
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{T,W}[])
    children = zeros(T, nv(g))
    dists = Vector{Union{Nothing,W}}(undef, nv(g))
    # Add source
    dists[arr] = zero(W)
    push!(heap, arr => zero(W))
    # Main loop
    while !isempty(heap)
        v, Δ_v = pop!(heap)
        if Δ_v <= dists[v]
            dists[v] = Δ_v
            for u in inneighbors(g, v)
                Δ_u = dists[u]
                Δ_u_through_v = w[u, v] + Δ_v
                if isnothing(Δ_u) || (Δ_u_through_v < Δ_u)
                    children[u] = v
                    dists[u] = Δ_u_through_v
                    push!(heap, u => Δ_u_through_v)
                end
            end
        end
    end
    return ShortestPathTree{T,Union{Nothing,W}}(children, dists)
end

"""
    dijkstra_by_arrival(mapf)

Run `backward_dijkstra` from each arrival vertex of a `MAPF`.

Returns a dictionary of `ShortestPathTree`s.
"""
function dijkstra_by_arrival(mapf::MAPF{W}; show_progress=false) where {W}
    unique_arrivals = unique(mapf.arrivals)
    K = length(unique_arrivals)
    spt_by_arr_vec = Vector{ShortestPathTree{Int,Union{Nothing,W}}}(undef, K)
    prog = Progress(K; desc="Dijkstra by destination: ", enabled=show_progress)
    for k in 1:K
        next!(prog)
        spt_by_arr_vec[k] = backward_dijkstra(
            mapf.g, mapf.edge_weights; arr=unique_arrivals[k]
        )
    end
    spt_by_arr = Dict{Int,ShortestPathTree{Int,Union{Nothing,W}}}(
        unique_arrivals[k] => spt_by_arr_vec[k] for k in 1:K
    )
    return spt_by_arr
end

"""
    independent_dijkstra_from_trees(mapf, spt_by_arr)

Compute independent shortest paths for each agent based on the output of `dijkstra_by_arrival` (i.e. a dictionary of `ShortestPathTree`s)
"""
function independent_dijkstra_from_trees(mapf::MAPF, spt_by_arr)
    A = nb_agents(mapf)
    solution = Vector{TimedPath}(undef, A)
    for a in 1:A
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        timed_path = build_path_tree(spt_by_arr[arr], dep, arr, tdep)
        solution[a] = timed_path
    end
    return solution
end

"""
    independent_dijkstra(mapf)

Compute independent shortest paths for each agent.
    
Returns a `Solution`.
"""
function independent_dijkstra(mapf::MAPF; show_progress=false)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    return solution
end
