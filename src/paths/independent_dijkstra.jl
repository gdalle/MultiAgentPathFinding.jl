"""
$(TYPEDEF)

Storage for the result of Dijkstra's algorithm run backwards.

# Fields

$(TYPEDFIELDS)
"""
struct ShortestPathTree{T,W}
    "successor of each vertex in a shortest path"
    children::Vector{T}
    "distance of each vertex to the arrival "
    dists::Vector{W}
end

"""
$(TYPEDSIGNATURES)

Build a [`TimedPath`](@ref) from a [`ShortestPathTree`](@ref), going from `dep` to `arr` and starting at time `tdep`.
"""
function build_path_from_tree(
    spt::ShortestPathTree{T}, dep::Integer, arr::Integer, tdep::Integer
) where {T}
    v = dep
    path = T[v]
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
function backward_dijkstra(g::AbstractGraph{T}, edge_costs; arr::Integer) where {T}
    W = eltype(edge_costs)
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
                Δ_u_through_v = edge_cost(edge_costs, u, v) + Δ_v
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
$(TYPEDSIGNATURES)

Run [`backward_dijkstra`](@ref) from each arrival vertex of `mapf`.

Returns a dictionary of [`ShortestPathTree`](@ref), one by arrival vertex.
"""
function dijkstra_by_arrival(mapf::MAPF{W}; show_progress=false) where {W}
    unique_arrivals = unique(mapf.arrivals)
    K = length(unique_arrivals)
    spt_by_arr_vec = Vector{ShortestPathTree{Int,Union{Nothing,W}}}(undef, K)
    prog = Progress(K; desc="Dijkstra by destination: ", enabled=show_progress)
    @threads for k in 1:K
        next!(prog)
        spt_by_arr_vec[k] = backward_dijkstra(
            mapf.g, mapf.edge_costs; arr=unique_arrivals[k]
        )
    end
    spt_by_arr = Dict{Int,ShortestPathTree{Int,Union{Nothing,W}}}(
        unique_arrivals[k] => spt_by_arr_vec[k] for k in 1:K
    )
    return spt_by_arr
end

"""
$(TYPEDSIGNATURES)

Compute independent shortest paths for each agent of `mapf` based on the output `spt_by_arr` of [`dijkstra_by_arrival`](@ref).

Returns a [`Solution`](@ref).
"""
function independent_dijkstra_from_trees(
    mapf::MAPF, spt_by_arr::Dict{<:Integer,<:ShortestPathTree}
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

"""
$(TYPEDSIGNATURES)

Compute independent shortest paths for each agent of `mapf`.
    
Returns a [`Solution`](@ref).
"""
function independent_dijkstra(mapf::MAPF; show_progress=false)
    spt_by_arr = dijkstra_by_arrival(mapf; show_progress)
    solution = independent_dijkstra_from_trees(mapf, spt_by_arr)
    return solution
end
