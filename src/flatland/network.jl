const FlatlandNetwork = DataDiGraph{
    Int,
    NTuple{4,Int},
    Nothing,
    Nothing,
    @NamedTuple{grid::Matrix{UInt16}, agents::Vector{Agent}}
}

function build_network(pyenv::Py, agents::Vector{Agent})
    # Find stations
    initial_positions = unique(agent.initial_position for agent in agents)
    target_positions = unique(agent.target_position for agent in agents)

    # Retrieve grid
    width = pyconvert(Int, pyenv.width)
    height = pyconvert(Int, pyenv.height)
    cell_grid = pyconvert(Matrix{UInt16}, pyenv.rail.grid)

    # Initialize network
    network = DataDiGraph{Int}(; VL=NTuple{4,Int}, graph_data=(grid=cell_grid, agents=agents))

    # Create vertices from non empty grid cells
    for i in 1:height, j in 1:width
        cell = cell_grid[i, j]
        if cell > 0
            transition_map = bitstring(cell)
            # Real vertices
            for direction in CARDINAL_POINTS
                if direction_exists(transition_map, direction)
                    label = (i, j, direction, REAL)
                    add_vertex!(network, label)
                end
            end
            # Departure vertices
            if (i, j) in initial_positions
                for direction in CARDINAL_POINTS
                    if direction_exists(transition_map, direction)
                        label = (i, j, direction, DEPARTURE)
                        add_vertex!(network, label)
                    end
                end
            end
            # Arrival vertices
            if (i, j) in target_positions
                label = (i, j, NO_DIRECTION, ARRIVAL)
                add_vertex!(network, label)
            end
        end
    end

    # Create out edges for every vertex
    for v in vertices(network)
        label_s = get_label(network, v)
        (i, j, direction, kind) = label_s
        # From real vertices
        if kind == REAL
            add_edge!(network, label_s, label_s)
            cell = cell_grid[i, j]
            transition_map = bitstring(cell)
            # ... to real vertices
            for out_direction in CARDINAL_POINTS
                if transition_exists(transition_map, direction, out_direction)
                    i2, j2 = neighbor_cell(i, j, out_direction)
                    label_d = (i2, j2, out_direction, REAL)
                    add_edge!(network, label_s, label_d)
                end
            end
            # ... to arrival vertices
            if (i, j) in target_positions
                label_d = (i, j, NO_DIRECTION, ARRIVAL)
                add_edge!(network, label_s, label_d)
            end
            # From departure vertices
        elseif kind == DEPARTURE
            add_edge!(network, label_s, label_s)
            # ... to real vertices
            label_d = (i, j, direction, REAL)
            add_edge!(network, label_s, label_d)
        end
    end
    return network
end

get_grid(network::FlatlandNetwork) = get_data(network).grid
get_agents(network::FlatlandNetwork) = get_data(network).agents
get_height(network::FlatlandNetwork) = size(get_grid(network), 1)
get_width(network::FlatlandNetwork) = size(get_grid(network), 2)

function build_conflict_groups(network::FlatlandNetwork)
    cell_grid = get_grid(network)
    h, w = size(cell_grid)
    conflict_groups = Vector{Int}[]
    # Add cell groups
    for i in 1:h, j in 1:w
        cell_grid[i, j] > 0 || continue
        group = vertices_on_cell(network, i, j)
        push!(conflict_groups, group)
    end
    # Add cell border groups
    for v in vertices(network)
        (i, j, direction, kind) = get_label(network, v)
        kind == REAL || continue
        v_mirror = mirror_vertex(network, v)
        [v_mirror, v] in conflict_groups && continue
        group = [v, v_mirror]
        push!(conflict_groups, group)
    end
    return conflict_groups
end

function generate_mapf(pyenv::Py)
    agents = [Agent(pyagent) for pyagent in pyenv.agents]
    network = build_network(pyenv, agents)
    sources = [get_vertex(network, initial_label(agent)) for agent in agents]
    destinations = [get_vertex(network, target_label(agent)) for agent in agents]
    starting_times = [agent.earliest_departure for agent in agents]
    conflict_groups = build_conflict_groups(network)
    mapf = MAPF(;
        graph=network,
        sources=sources,
        destinations=destinations,
        starting_times=starting_times,
        conflict_groups=conflict_groups,
        edge_weights=Ones{Float64}(nv(network), nv(network)),
    )
    return mapf
end
