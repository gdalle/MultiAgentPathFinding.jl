"""
$(TYPEDEF)

Storage for the result of Dijkstra's algorithm run backwards.

# Fields

$(TYPEDFIELDS)
"""
struct ShortestPathTree{V,W}
    "successor of each vertex in a shortest path"
    children::Vector{V}
    "distance of each vertex to the arrival "
    dists::Vector{W}
end

"""
$(TYPEDSIGNATURES)

Build a [`TimedPath`](@ref) from a [`ShortestPathTree`](@ref), going from `dep` to `arr` and starting at time `tdep`.
"""
function build_path_from_tree(
    spt::ShortestPathTree{V}, dep::Integer, arr::Integer, tdep::Integer
) where {V}
    v = dep
    path = V[v]
    while v != arr
        v = spt.children[v]
        push!(path, v)
    end
    return TimedPath(tdep, path)
end

"""
$(TYPEDSIGNATURES)

Run Dijkstra's algorithm backward on graph `g` from arrival vertex `arr`, with specified `edge_costs`.

Returns a [`ShortestPathTree`](@ref) where distances can be `nothing`.
"""
function backward_dijkstra(g::AbstractGraph, edge_costs; arr::Integer)
    V = Int
    W = eltype(edge_costs)
    # Init storage
    heap = BinaryHeap(Base.By(last), Pair{V,W}[])
    children = zeros(V, nv(g))
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
                Δ_u_through_v = edge_cost(edge_costs, u, v) + Δ_v
                if isnothing(Δ_u) || (Δ_u_through_v < Δ_u)
                    children[u] = v
                    dists[u] = Δ_u_through_v
                    push!(heap, u => Δ_u_through_v)
                end
            end
        end
    end
    return ShortestPathTree{V,Union{Nothing,W}}(children, dists)
end

"""
$(TYPEDSIGNATURES)

Run [`backward_dijkstra`](@ref) from each arrival vertex of `mapf`.

Returns a dictionary of [`ShortestPathTree`](@ref), one by arrival vertex.
"""
function dijkstra_by_arrival(mapf::MAPF; show_progress=false, threaded=true)
    V = Int
    W = eltype(mapf.edge_costs)
    unique_arrivals = unique(mapf.arrivals)
    K = length(unique_arrivals)
    prog = Progress(K; desc="Dijkstra by destination: ", enabled=show_progress)
    spt_by_arr_vec = if threaded
        tmap(1:K) do k
            next!(prog)
            backward_dijkstra(mapf.g, mapf.edge_costs; arr=unique_arrivals[k])
        end
    else
        map(1:K) do k
            next!(prog)
            backward_dijkstra(mapf.g, mapf.edge_costs; arr=unique_arrivals[k])
        end
    end
    spt_by_arr = Dict{V,ShortestPathTree{V,Union{Nothing,W}}}(
        unique_arrivals[k] => spt_by_arr_vec[k] for k in 1:K
    )
    return spt_by_arr
end

"""
$(TYPEDSIGNATURES)

Compute independent shortest paths for each agent of `mapf`.
    
Returns a [`Solution`](@ref).
"""
function independent_dijkstra(
    mapf::MAPF;
    show_progress=false,
    threaded=true,
    spt_by_arr=dijkstra_by_arrival(mapf; show_progress, threaded),
)
    A = nb_agents(mapf)
    timed_paths = Dict{Int,TimedPath}()
    for a in 1:A
        dep, arr = mapf.departures[a], mapf.arrivals[a]
        tdep = mapf.departure_times[a]
        timed_path = build_path_from_tree(spt_by_arr[arr], dep, arr, tdep)
        timed_paths[a] = timed_path
    end
    return Solution(timed_paths)
end
