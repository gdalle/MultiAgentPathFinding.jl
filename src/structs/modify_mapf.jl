"""
    select_agents(mapf, agents)

Select a subset of agents and return a new `MAPF`.
"""
function select_agents(mapf::MAPF, agents)
    @assert issubset(agents, eachindex(mapf.departures))
    return MAPF(
        # Graph-related
        mapf.g,
        # Agents-related
        view(mapf.departures, agents),
        view(mapf.arrivals, agents),
        view(mapf.departure_times, agents),
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
        # Edges-related
        mapf.edge_indices,
        mapf.edge_colptr,
        mapf.edge_rowval,
        mapf.edge_weights_vec,
        # Misc
        mapf.flexible_departure,
    )
end

"""
    select_agents(mapf, nb_agents)

Select the first `nb_agents` and return a new `MAPF`.
"""
select_agents(mapf::MAPF, nb_agents::Integer) = select_agents(mapf, 1:nb_agents)

"""
    replace_agents(mapf, new_departures, new_arrivals, new_departure_times)

Return a new `MAPF` with fresh agent data.
"""
function replace_agents(mapf::MAPF, new_departures, new_arrivals, new_departure_times)
    return MAPF(
        # Graph-related
        mapf.g,
        # Agents-related
        new_departures,
        new_arrivals,
        new_departure_times,
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
        # Edges-related
        mapf.edge_indices,
        mapf.edge_colptr,
        mapf.edge_rowval,
        mapf.edge_weights_vec,
        # Misc
        mapf.flexible_departure,
    )
end
