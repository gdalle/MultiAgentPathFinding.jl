const FlatlandMAPF = MAPF{FlatlandGraph}

function flatland_vertex_conflicts(g::FlatlandGraph, v::Integer)
    if is_real_vertex(g, v)
        mv = mirror_vertex(g, v)
        cv = vertices_on_cell(g, v)
        return Int[mv, cv...]
    else
        return Int[]
    end
end

function flatland_mapf(pyenv::Py)
    agents = [Agent(pyagent) for pyagent in pyenv.agents]
    g = flatland_graph(pyenv, agents)
    sources = [get_vertex(g, initial_label(agent)) for agent in agents]
    destinations = [get_vertex(g, target_label(agent)) for agent in agents]
    starting_times = [agent.earliest_departure for agent in agents]
    vertex_conflicts = [flatland_vertex_conflicts(g, v) for v in vertices(g)]
    mapf = MAPF(
        g,
        sources,
        destinations;
        starting_times=starting_times,
        vertex_conflicts=vertex_conflicts,
    )
    return mapf
end
