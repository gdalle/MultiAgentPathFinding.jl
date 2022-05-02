const FlatlandGraph = DataDiGraph{Int,NTuple{4,Int},Nothing,Float64,Matrix{UInt16}}

function flatland_graph(pyenv::Py, agents::Vector{Agent})
    # Find stations
    initial_positions = unique(agent.initial_position for agent in agents)
    target_positions = unique(agent.target_position for agent in agents)

    # Retrieve grid
    width = pyconvert(Int, pyenv.width)
    height = pyconvert(Int, pyenv.height)
    grid = pyconvert(Matrix{UInt16}, pyenv.rail.grid)

    # Initialize g
    g = DataDiGraph{Int}(;
        VL=NTuple{4,Int}, VD=Nothing, ED=Float64, graph_data=grid
    )

    # Create vertices from non empty grid cells
    for i in 1:height, j in 1:width
        cell = grid[i, j]
        if cell > 0
            transition_map = bitstring(cell)
            # Real vertices
            for direction in CARDINAL_POINTS
                if direction_exists(transition_map, direction)
                    label = (i, j, direction, REAL)
                    add_vertex!(g, label)
                end
            end
            # Departure vertices
            if (i, j) in initial_positions
                for direction in CARDINAL_POINTS
                    if direction_exists(transition_map, direction)
                        label = (i, j, direction, DEPARTURE)
                        add_vertex!(g, label)
                    end
                end
            end
            # Arrival vertices
            if (i, j) in target_positions
                label = (i, j, NO_DIRECTION, ARRIVAL)
                add_vertex!(g, label)
            end
        end
    end

    # Create out edges for every vertex
    for v in vertices(g)
        label_s = get_label(g, v)
        (i, j, direction, kind) = label_s
        if kind == REAL  # from real vertices
            cell = grid[i, j]
            transition_map = bitstring(cell)
            # to themselves
            add_edge!(g, label_s, label_s, 1.0)
            # to other real vertices
            for out_direction in CARDINAL_POINTS
                if transition_exists(transition_map, direction, out_direction)
                    i2, j2 = neighbor_cell(i, j, out_direction)
                    label_d = (i2, j2, out_direction, REAL)
                    add_edge!(g, label_s, label_d, 1.0)
                end
            end
            # to arrival vertices
            if (i, j) in target_positions
                label_d = (i, j, NO_DIRECTION, ARRIVAL)
                add_edge!(g, label_s, label_d, 0.0)
            end
        elseif kind == DEPARTURE  # from departure vertices
            # to themselves
            add_edge!(g, label_s, label_s, 1.0)
            # to real vertices
            label_d = (i, j, direction, REAL)
            add_edge!(g, label_s, label_d, 0.0)
        elseif kind == ARRIVAL  # from arrival vertices
            # to themselves
            add_edge!(g, label_s, label_s, 0.0)
        end
    end
    return g
end

get_grid(g::FlatlandGraph) = get_data(g)
get_height(g::FlatlandGraph) = size(get_grid(g), 1)
get_width(g::FlatlandGraph) = size(get_grid(g), 2)
