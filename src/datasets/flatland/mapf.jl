const FlatlandMAPF = MAPF{FlatlandGraph}

function build_vertex_groups(g::FlatlandGraph)
    grid = get_grid(g)
    h, w = size(grid)
    vertex_groups = Vector{Int}[]
    # Add cell groups
    for i in 1:h, j in 1:w
        grid[i, j] > 0 || continue
        group = vertices_on_cell(g, i, j)
        push!(vertex_groups, group)
    end
    # Add cell border groups
    for v in vertices(g)
        (_, _, _, kind) = get_label(g, v)
        kind == REAL || continue
        v_mirror = mirror_vertex(g, v)
        [v_mirror, v] in vertex_groups && continue
        group = [v, v_mirror]
        push!(vertex_groups, group)
    end
    return vertex_groups
end

function flatland_vertex_conflict_lister(mapf::FlatlandMAPF, v::Integer)
    g = mapf.graph
    (i, j, direction, kind) = get_label(g, v)
    if kind == REAL
        mv = mirror_vertex(g, (i, j, direction, kind))
        cv = vertices_on_cell(g, (i, j, direction, kind))
        return Iterators.flatten((v, mv, cv))
    else
        return nothing
    end
end

function flatland_mapf(pyenv::Py)
    agents = [Agent(pyagent) for pyagent in pyenv.agents]
    g = flatland_graph(pyenv, agents)
    sources = [get_vertex(g, initial_label(agent)) for agent in agents]
    destinations = [get_vertex(g, target_label(agent)) for agent in agents]
    starting_times = [agent.earliest_departure for agent in agents]
    mapf = MAPF(
        g,
        sources,
        destinations;
        starting_times=starting_times,
        vertex_conflict_lister=flatland_vertex_conflict_lister,
    )
    return mapf
end
