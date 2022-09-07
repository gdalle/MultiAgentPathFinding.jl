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
    )
end

"""
    add_departure_waiting_vertices(mapf[; waiting_cost=1])

Add dummy vertices with self-loops before agent departure vertices, so that they may start their journey after their prescribed departure times.
"""
function add_departure_waiting_vertices(mapf::MAPF{W}; waiting_cost=one(W)) where {W}
    @assert waiting_cost > 0

    A = length(mapf.departures)
    V = nv(mapf.g)
    edge_weights_mat = Graphs.weights(mapf.g)

    augmented_sources = src.(edges(mapf.g))
    augmented_destinations = dst.(edges(mapf.g))
    augmented_weights = Float64[edge_weights_mat[src(ed), dst(ed)] for ed in edges(mapf.g)]
    augmented_vertex_conflicts = Dict(
        v => collect(mapf.vertex_conflicts[v]) for v in vertices(mapf.g)
    )
    augmented_edge_conflicts = Dict(
        (src(ed), dst(ed)) => collect(mapf.edge_conflicts[(src(ed), dst(ed))]) for
        ed in edges(mapf.g)
    )

    new_departures = (V + 1):(V + A)
    append!(augmented_sources, new_departures, new_departures)
    append!(augmented_destinations, new_departures, mapf.departures)
    append!(augmented_weights, fill(waiting_cost, A), fill(waiting_cost, A))
    for (u, v) in zip(new_departures, mapf.departures)
        augmented_vertex_conflicts[u] = Int[]
        augmented_edge_conflicts[(u, u)] = Tuple{Int,Int}[]
        augmented_edge_conflicts[(u, v)] = Tuple{Int,Int}[]
    end

    augmented_g = SimpleWeightedDiGraph(
        augmented_sources, augmented_destinations, augmented_weights
    )

    return MAPF(
        augmented_g;
        departures=new_departures,
        arrivals=mapf.arrivals,
        departure_times=mapf.departure_times,
        vertex_conflicts=augmented_vertex_conflicts,
        edge_conflicts=augmented_edge_conflicts,
    )
end
