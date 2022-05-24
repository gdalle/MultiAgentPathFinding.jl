function mapf_embedding(s::Integer, d::Integer, a::Integer, solution::Solution, mapf::MAPF)
    fe1 = graph_features_edge(s, d, mapf)
    fe2 = mission_features_edge(s, d, mapf)
    fe3 = conflict_features_edge(s, d, mapf)
    fe4 = solution_features_edge(s, d, solution, mapf)

    fea1 = features_edge_agent(s, d, a, solution, mapf)

    fa1 = mission_features_agent(a, mapf)
    fa2 = path_features_agent(a, solution, mapf)
    fa3 = conflict_features_agent(a, solution, mapf)

    x = Float64[]
    for f in (fe1, fe2, fe3, fe4, fea1, fa1, fa2, fa3)
        for y in f
            push!(x, y)
        end
    end
    return x
end

function mapf_embedding_nb_features(solution::Solution, mapf::MAPF)
    (; g) = mapf
    ed = first(edges(g))
    x = mapf_embedding(src(ed), dst(ed), 1, solution, mapf)
    return length(x)
end

function mapf_embedding(a::Integer, solution::Solution, mapf::MAPF)
    (; g, edge_indices) = mapf
    E = ne(g)
    F = mapf_embedding_nb_features(solution, mapf)
    x = Matrix{Float64}(undef, F, E)
    fa1 = mission_features_agent(a, mapf)
    fa2 = path_features_agent(a, solution, mapf)
    fa3 = conflict_features_agent(a, solution, mapf)
    for s in 1:nv(g)
        for d in outneighbors(g, s)
            e::Int = edge_indices[s, d]
            fe1 = graph_features_edge(s, d, mapf)
            fe2 = mission_features_edge(s, d, mapf)
            fe3 = conflict_features_edge(s, d, mapf)
            fe4 = solution_features_edge(s, d, solution, mapf)
            fea1 = features_edge_agent(s, d, a, solution, mapf)
            i = 1
            for f in (fe1, fe2, fe3, fe4, fea1, fa1, fa2, fa3)
                for y in f
                    x[i, e] = y
                    i += 1
                end
            end
        end
    end
    m = mean(x; dims=2)
    s = std(x; dims=2)
    s[iszero.(s)] .= 1.0
    x .= (x .- m) ./ s
    return x
end

function mapf_embedding(solution::Solution, mapf::MAPF)
    (; g) = mapf
    E = ne(g)
    F = mapf_embedding_nb_features(solution, mapf)
    A = nb_agents(mapf)
    x = Array{Float64,3}(undef, F, E, A)
    @threads for a in 1:A
        x[:, :, a] .= mapf_embedding(a, solution, mapf)
    end
    m = mean(x; dims=(2, 3))
    s = std(x; dims=(2, 3))
    s[iszero.(s)] .= 1.0
    x .= (x .- m) ./ s
    return x
end
