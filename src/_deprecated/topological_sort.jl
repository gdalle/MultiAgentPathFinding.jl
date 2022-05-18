
function independent_topological_sort(
    mapf::MAPF, edge_weights::AbstractVector=mapf.edge_weights; T::Integer
)
    rev_g = mapf.rev_graph

    V = nv(rev_g)
    A = nb_agents(mapf)

    solution = Vector{Path}(undef, A)
    dists = OffsetMatrix{Float64}(undef, 0:T, V)
    parents = Matrix{Int}(undef, T, V)

    for d in unique(mapf.destinations)
        for v in vertices(rev_g)
            dists[0, v] = v == d ? 0.0 : Inf
        end
        for t in 1:T, v in 1:V
            dists[t, v] = Inf
            parents[t, v] = 0
            for u in inneighbors(rev_g, v)
                dist_du = dists[t - 1, u]
                weight_uv = edge_weights[mapf.rev_edge_indices[u, v]]
                if dist_du + weight_uv < dists[t, v]
                    dists[t, v] = dist_du + weight_uv
                    parents[t, v] = u
                end
            end
        end
        for a in 1:A
            mapf.destinations[a] == d || continue
            s = mapf.sources[a]
            t0 = mapf.starting_times[a]
            tf = minimum(t for t = 1:T if dists[t, s] < Inf)
            t, v = tf, s
            path = [(t0 + tf - t, v)]
            while v != d
                v = parents[t, v]
                t -= 1
                push!(path, (t0 + tf - t, v))
            end
            solution[a] = path
        end
    end
    return solution
end
