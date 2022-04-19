function solve_lp(mapf::MAPF; T::Integer, integer=false)
    @assert all(<=(T), mapf.starting_times)

    A = nb_agents(mapf)
    G = mapf.graph
    V, E = nv(G), ne(G)
    W = [mapf.edge_weights[src(ed), dst(ed)] for ed in edges(mapf.graph)]

    model = Model(Cbc.Optimizer)

    @variable(model, x[1:A, 1:(T - 1), 1:E])
    @variable(model, y[1:A, 1:T, 1:V])

    @objective(model, Min, dot(W, sum(x; dims=(1, 2))))

    if integer
        set_binary.(x)
        set_binary.(y)
    else
        @constraint(model, 0 .<= x .<= 1)
        @constraint(model, 0 .<= y .<= 1)
    end

    @showprogress for a in 1:A
        s = mapf.sources[a]
        d = mapf.destinations[a]
        t0 = mapf.starting_times[a]
        for t = 1:t0-1
            @constraint(model, y[a, t, :] .== 0)
            @constraint(model, x[a, t, :] .== 0)
        end
        for t in t0:T
            @constraint(model, sum(@view y[a, t, :]) == 1)
        end
        @constraint(model, y[a, t0, s] == 1)
        @constraint(model, y[a, T, d] == 1)
    end

    @showprogress for v in 1:V
        e_in = [e for (e, ed) in enumerate(edges(G)) if dst(ed) == v]
        e_out = [e for (e, ed) in enumerate(edges(G)) if src(ed) == v]
        for a in 1:A
            t0 = mapf.starting_times[a]
            for t in t0:(T - 1)
                @constraint(model, y[a, t, v] == sum(@view x[a, t, e_out]))
            end
            for t in (t0 + 1):T
                @constraint(model, y[a, t, v] == sum(@view x[a, t - 1, e_in]))
            end
        end
    end

    @showprogress for group in mapf.conflict_groups
        for t in 1:T
            @constraint(model, sum(@view y[:, t, group]) <= 1)
        end
    end

    optimize!(model)

    return termination_status(model), objective_value(model)
end
