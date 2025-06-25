struct DijkstraStorage{V,W,H<:BinaryHeap}
    parents::Vector{V}
    dists::Vector{W}
    heap::H
end

function DijkstraStorage(g::SimpleWeightedGraph)
    V, W = eltype(g), weighttype(g)
    parents = Vector{V}(undef, nv(g))
    dists = Vector{W}(undef, nv(g))
    heap = BinaryHeap(Base.By(last), Pair{V,W}[])
    sizehint!(heap, nv(g))
    return DijkstraStorage(parents, dists, heap)
end

function reset!(storage::DijkstraStorage{V,W}) where {V,W}
    (; heap, parents, dists) = storage
    empty!(heap.valtree)  # internal, will be released in DataStructures v0.19
    fill!(parents, zero(V))
    fill!(dists, typemax(W))
    return nothing
end

function dijkstra!(storage::DijkstraStorage, g::SimpleWeightedGraph, dep::Integer)
    reset!(storage)
    (; heap, parents, dists) = storage
    W = weighttype(g)
    # Add source
    push!(heap, dep => zero(W))
    # Main loop
    while !isempty(heap)
        u, du = pop!(heap)
        if du <= dists[u]
            dists[u] = du
            for (v, w_uv) in neighbors_and_weights(g, u)
                if du + w_uv < dists[v]
                    parents[v] = u
                    dists[v] = du + w_uv
                    push!(heap, v => du + w_uv)
                end
            end
        end
    end
    return nothing
end

function dijkstra(g::SimpleWeightedGraph, dep::Integer)
    storage = init_dijkstra(g)
    dijkstra!(storage, g, dep)
    return storage
end

function reconstruct_path(storage::DijkstraStorage, dep::Integer, arr::Integer)
    (; parents) = storage
    path = [arr]
    v = arr
    while parents[v] != 0
        v = parents[v]
        push!(path, v)
    end
    @assert last(path) == dep
    return reverse(path)
end

"""
$(TYPEDSIGNATURES)

Compute independent shortest paths for each agent of `mapf`.
    
Returns a `Solution` where some paths may be empty if the vertices are not connected.
"""
function independent_dijkstra(mapf::MAPF)
    (; g, departures, arrivals) = mapf
    storage = DijkstraStorage(g)
    A = nb_agents(mapf)
    paths = Vector{Path}(undef, A)
    for a in 1:A
        dep, arr = departures[a], arrivals[a]
        dijkstra!(storage, g, dep)
        paths[a] = reconstruct_path(storage, dep, arr)
    end
    return Solution(paths)
end
