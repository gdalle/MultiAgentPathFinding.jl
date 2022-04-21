function rail_coords(mapf::MAPF)
    g::FlatlandGraph = mapf.graph

    P1 = Dict(NORTH => (0, -0.5), EAST => (-0.5, 0), SOUTH => (0, 0.5), WEST => (0.5, 0))
    P2 = Dict(NORTH => (0, -0.3), EAST => (-0.3, 0), SOUTH => (0, 0.3), WEST => (0.3, 0))
    P3 = Dict(NORTH => (0, 0.3), EAST => (0.3, 0), SOUTH => (0, -0.3), WEST => (-0.3, 0))
    P4 = Dict(NORTH => (0, 0.5), EAST => (0.5, 0), SOUTH => (0, -0.5), WEST => (-0.5, 0))

    grid = get_grid(g)
    h, w = size(grid)
    X_lines, Y_lines = Float64[], Float64[]
    X_limits, Y_limits = Float64[], Float64[]
    X_stations, Y_stations = Float64[], Float64[]

    station_vertices = union(mapf.sources, mapf.destinations)
    station_coords = [get_label(g, v)[1:2] for v in station_vertices]

    for i in 1:h, j in 1:w
        cell = grid[i, j]
        if cell > 0
            transition_map = bitstring(cell)
            for direction in CARDINAL_POINTS, destination in CARDINAL_POINTS
                if transition_exists(transition_map, direction, destination)
                    p1, p2 = P1[direction], P2[direction]
                    p3, p4 = P3[destination], P4[destination]
                    X_cell = [p1[1], p2[1], p3[1], p4[1], NaN]
                    Y_cell = [p1[2], p2[2], p3[2], p4[2], NaN]

                    append!(X_lines, j .+ X_cell)
                    append!(Y_lines, (h - i + 1) .+ Y_cell)

                    append!(X_limits, j .+ X_cell[[1, end - 1]])
                    append!(Y_limits, (h - i + 1) .+ Y_cell[[1, end - 1]])
                end
            end

            if (i, j) in station_coords
                append!(X_stations, j .+ 0.7 * [-0.5, 0.5, 0.5, -0.5, -0.5, NaN])
                append!(Y_stations, (h - i + 1) .+ 0.7 * [-0.5, -0.5, 0.5, 0.5, -0.5, NaN])
            end
        end
    end
    return (X_lines, Y_lines), (X_limits, Y_limits), (X_stations, Y_stations)
end

function flatland_agent_coords(mapf::MAPF, solution::Solution, t::Integer)
    g::FlatlandGraph = mapf.graph
    h, w = get_height(g), get_width(g)
    XY = Tuple{Float64,Float64}[]
    M, A = Symbol[], Int[]

    for a in 1:length(solution)
        path = solution[a]
        for (s, v) in path
            if s == t
                i, j, direction, kind = get_label(g, v)
                if kind == REAL
                    x, y = j, h - i + 1
                    if direction == NORTH
                        m = :utriangle
                    elseif direction == EAST
                        m = :rtriangle
                    elseif direction == SOUTH
                        m = :dtriangle
                    elseif direction == WEST
                        m = :ltriangle
                    else
                        m = :xcross
                    end

                    push!(A, a)
                    push!(XY, (x, y))
                    push!(M, m)
                end
            end
        end
    end

    return A, XY, M
end

function add_agents!(ax)
    A = Observable(Int[])
    XY = Observable(Point2f[])
    M = Observable(Symbol[])
    scatter!(ax, XY; marker=:rect, color=:red, markersize=30)
    scatter!(ax, XY; marker=M, color="white", markersize=15)
    text!(ax, @lift(string.($A)); position=XY, color="black", align=(:center, :center))
    return A, XY, M
end

function plot_flatland_graph(mapf::MAPF)
    g::FlatlandGraph = mapf.graph
    xy_lines, xy_limits, xy_stations = rail_coords(mapf)
    h, w = get_height(g), get_width(g)
    fig = Figure(; figure_padding=1)
    ax = GLMakie.Axis(fig[1, 1]; xticks=1:w, yticks=(1:h, string.(h:-1:1)))
    Makie.lines!(ax, xy_lines...; color="black")
    ax.aspect = DataAspect()
    scatter!(ax, xy_limits...; color="black", marker=:cross)
    Makie.lines!(ax, xy_stations...; color="black")
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    resize_to_layout!(fig)
    A, XY, M = add_agents!(ax)
    return fig, (A, XY, M)
end
