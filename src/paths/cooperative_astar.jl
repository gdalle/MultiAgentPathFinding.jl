struct NoConflictFreePathError <: Exception
    dep::Int
    arr::Int
end

function Base.showerror(io::IO, e::NoConflictFreePathError)
    return print(
        io,
        "NoConflictFreePathError: No conflict-free path was found from vertex $(e.dep) to vertex $(e.arr) in the graph, given the provided reservation.",
    )
end

struct TemporalAstarStorage{T,V,W,H<:BinaryHeap}
    parents::Dict{Tuple{T,V},Tuple{T,V}}
    dists::Dict{Tuple{T,V},W}
    heap::H
end

function TemporalAstarStorage(g::SimpleWeightedGraph)
    T, V, W = Int, eltype(g), weighttype(g)
    parents = Dict{Tuple{T,V},Tuple{T,V}}()
    dists = Dict{Tuple{T,V},W}()
    heap = BinaryHeap(Base.By(last ∘ last), Pair{Tuple{T,V},Tuple{W,W}}[])
    sizehint!(heap, nv(g))
    return TemporalAstarStorage(parents, dists, heap)
end

function reset!(storage::TemporalAstarStorage{W,V}) where {W,V}
    (; heap, parents, dists) = storage
    empty!(heap.valtree)  # internal, will be released in DataStructures v0.19
    empty!(parents)
    empty!(dists)
    return nothing
end

struct AstarConvergenceError <: Exception
    max_nodes::Int
    nv::Int
    ne::Int
end

function Base.showerror(io::IO, e::AstarConvergenceError)
    return print(
        io,
        "Temporal A* explored more than $(e.max_nodes) nodes on a graph with $(e.nv) vertices and $(e.ne) edges",
    )
end

function temporal_astar!(
    storage::TemporalAstarStorage,
    g::SimpleWeightedGraph,
    dep::Integer,
    arr::Integer;
    heuristic::Vector,
    reservation::Reservation,
)
    reset!(storage)
    (; heap, parents, dists) = storage
    W = weighttype(g)
    # Add source
    if !is_occupied_vertex(reservation, 1, dep)
        dists[1, dep] = zero(W)
        push!(heap, (1, dep) => (zero(W), heuristic[dep]))
    end
    # Main loop
    while !isempty(heap)
        (t, u), (du, hu) = pop!(heap)
        if t > reservation.max_time[] + nv(g) + 1
            # if there is a path, it will have been found before that time
            continue
        elseif u == arr && is_safe_vertex_to_stop(reservation, t, u)
            path = reconstruct_path(storage, dep, arr, t)
            return path
        elseif du <= dists[t, u]
            dists[t, u] = du
            for (v, w_uv) in neighbors_and_weights(g, u)
                heuristic[v] == typemax(W) && continue
                is_occupied_vertex(reservation, t + 1, v) && continue
                is_occupied_edge(reservation, t, u, v) && continue
                dv = get(dists, (t + 1, v), typemax(W))
                if du + w_uv < dv
                    parents[t + 1, v] = (t, u)
                    dists[t + 1, v] = du + w_uv
                    hv = du + w_uv + heuristic[v]
                    push!(heap, (t + 1, v) => (du + w_uv, hv))
                end
            end
        end
    end
    throw(NoConflictFreePathError(dep, arr))
end

function temporal_astar(
    g::SimpleWeightedGraph, dep::Integer, arr::Integer; heuristic, reservation::Reservation
)
    storage = TemporalAstarStorage(g)
    return temporal_astar!(storage, g, dep, arr; heuristic, reservation)
end

function reconstruct_path(
    storage::TemporalAstarStorage, dep::Integer, arr::Integer, tarr::Integer
)
    (; parents) = storage
    path = [arr]
    (t, v) = (tarr, arr)
    while haskey(parents, (t, v))
        (t, v) = parents[t, v]
        push!(path, v)
    end
    @assert last(path) == dep
    return reverse(path)
end

"""
$(TYPEDSIGNATURES)

Solve a MAPF problem `mapf` for a set of `agents` with the cooperative A* algorithm of Silver (2005), see <https://ojs.aaai.org/index.php/AIIDE/article/view/18726>.

Returns a `Solution` where some paths may be empty if the vertices are not connected.
"""
function cooperative_astar(
    mapf::MAPF, agents::AbstractVector{<:Integer}=1:nb_agents(mapf); kwargs...
)
    (; graph, departures, arrivals) = mapf
    dijkstra_storage = DijkstraStorage(graph)
    temporal_astar_storage = TemporalAstarStorage(graph)
    reservation = Reservation()
    A = nb_agents(mapf)
    paths = Vector{Path}(undef, A)
    for a in agents
        dep, arr = departures[a], arrivals[a]
        dijkstra!(dijkstra_storage, graph, arr)  # graph is undirected
        heuristic = dijkstra_storage.dists
        path = temporal_astar!(
            temporal_astar_storage, graph, dep, arr; reservation, heuristic, kwargs...
        )
        update_reservation!(reservation, path, a, mapf)
        paths[a] = path
    end
    return Solution(paths)
end
