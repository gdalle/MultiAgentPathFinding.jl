function solve_lp(mapf::MAPF; T::Integer, integer=false, capacity=true)
    @assert all(<=(T), mapf.starting_times)

    g = mapf.graph
    w_vec = [mapf.edge_weights[src(ed), dst(ed)] for ed in edges(g)]

    A = nb_agents(mapf)
    V, E = nv(g), ne(g)

    model = Model(SCIP.Optimizer)

    @variable(model, x[1:A, 1:(T - 1), 1:E])
    @variable(model, y[1:A, 1:T, 1:V])

    @objective(model, Min, dot(w_vec, sum(x; dims=(1, 2))))

    if integer
        set_binary.(x)
        set_binary.(y)
    else
        @constraint(model, 0 .<= x .<= 1)
        @constraint(model, 0 .<= y .<= 1)
    end

    for a in 1:A
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

    for v in 1:V
        e_in = [e for (e, ed) in enumerate(edges(g)) if dst(ed) == v]
        e_out = [e for (e, ed) in enumerate(edges(g)) if src(ed) == v]
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

    if capacity
        for group in mapf.conflict_groups
            for t in 1:T
                @constraint(model, sum(@view y[:, t, group]) <= 1)
            end
        end
    end

    optimize!(model)

    stat = termination_status(model)
    solution = Solution()

    if stat == MOI.OPTIMAL
        val = objective_value(model)
        yopt = value.(y)
        for a = 1:A
            path = Path()
            t0 = mapf.starting_times[a]
            for t = t0:T
                v = argmax(@view yopt[a, t, :])
                push!(path, (t, v))
                v == mapf.destinations[a] && break
            end
            push!(solution, path)
        end
    else
        val = Inf
    end

    return stat, val, solution
end
