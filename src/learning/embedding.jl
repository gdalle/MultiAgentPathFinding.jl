function mapf_embedding(mapf::MAPF)
    solution_indep = independent_dijkstra(mapf)
    F, E = size(all_edges_embedding(1, solution_indep, mapf))
    A = nb_agents(mapf)
    x = Array{Float64, 3}(undef, F, E, A)
    @threads for a in 1:A
        x_a = all_edges_embedding(a, solution_indep, mapf)
        m = mean(x_a; dims=2)
        s = std(x_a; dims=2)
        s[iszero.(s)] .= 1.0
        x_a .-= m
        x_a ./= s
        x[:, :, a] = x_a
    end
    return x
end
