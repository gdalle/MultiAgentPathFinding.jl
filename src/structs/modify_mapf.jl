function select_agents(mapf::MAPF, agents)
    @assert issubset(agents, eachindex(mapf.departures))
    return MAPF(
        # Graph-related
        mapf.g,
        # Edges-related
        mapf.edge_indices,
        mapf.edge_colptr,
        mapf.edge_rowval,
        mapf.edge_weights_vec,
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
        # Agents-related
        view(mapf.departures, agents),
        view(mapf.arrivals, agents),
        view(mapf.departure_times, agents),
        mapf.stay_at_arrival;
        # Checks
        check_sorted=false,
    )
end

select_agents(mapf::MAPF, nb_agents::Integer) = select_agents(mapf, 1:nb_agents)

function replace_agents(mapf::MAPF, new_departures, new_arrivals, new_departure_times)
    return MAPF(
        # Graph-related
        mapf.g,
        # Edges-related
        mapf.edge_indices,
        mapf.edge_colptr,
        mapf.edge_rowval,
        mapf.edge_weights_vec,
        # Constraints-related
        mapf.vertex_conflicts,
        mapf.edge_conflicts,
        # Agents-related
        new_departures,
        new_arrivals,
        new_departure_times,
        mapf.stay_at_arrival;
        # Checks
        check_sorted=false,
    )
end

function add_dummy_vertices(
    mapf::MAPF{W};
    appear_at_departure=true,
    disappear_at_arrival=true,
    departure_loop_weight=one(W),
    arrival_loop_weight=one(W),
) where {W}
    @assert departure_loop_weight > 0
    @assert arrival_loop_weight > 0

    A = length(mapf.departures)
    V = nv(mapf.g)
    edge_weights_mat = Graphs.weights(mapf.g)

    augmented_sources = src.(edges(mapf.g))
    augmented_destinations = dst.(edges(mapf.g))
    augmented_weights = Float64[edge_weights_mat[src(ed), dst(ed)] for ed in edges(mapf.g)]
    augmented_vertex_conflicts = copy(mapf.vertex_conflicts)
    augmented_edge_conflicts = copy(mapf.edge_conflicts)

    new_departures = copy(mapf.departures)
    new_arrivals = copy(mapf.arrivals)

    if appear_at_departure
        new_departures .= (V + 1):(V + A)
        append!(augmented_sources, new_departures, new_departures)
        append!(augmented_destinations, new_departures, mapf.departures)
        append!(augmented_weights, fill(departure_loop_weight, A), fill(eps(0.0), A))
        for (u, v) in zip(new_departures, mapf.departures)
            augmented_vertex_conflicts[u] = Int[]
            augmented_edge_conflicts[(u, u)] = Tuple{Int,Int}[]
            augmented_edge_conflicts[(u, v)] = Tuple{Int,Int}[]
        end
        V += A
    end

    if disappear_at_arrival
        new_arrivals .= (V + 1):(V + A)
        append!(augmented_sources, mapf.arrivals, new_arrivals)
        append!(augmented_destinations, new_arrivals, new_arrivals)
        append!(augmented_weights, fill(eps(0.0), A), fill(arrival_loop_weight, A))
        for (u, v) in zip(mapf.arrivals, new_arrivals)
            augmented_vertex_conflicts[v] = Int[]
            augmented_edge_conflicts[(u, v)] = Tuple{Int,Int}[]
            augmented_edge_conflicts[(v, v)] = Tuple{Int,Int}[]
        end
        V += A
    end

    augmented_g = SimpleWeightedDiGraph(
        augmented_sources, augmented_destinations, augmented_weights
    )

    return MAPF(
        augmented_g,
        new_departures,
        new_arrivals;
        vertex_conflicts=augmented_vertex_conflicts,
        edge_conflicts=augmented_edge_conflicts,
        departure_times=mapf.departure_times,
        stay_at_arrival=mapf.stay_at_arrival,
    )
end
