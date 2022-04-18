function rail_coords(network::FlatlandNetwork)
    agents = get_agents(network)

    P1 = Dict(NORTH => (0, -0.5), EAST => (-0.5, 0), SOUTH => (0, 0.5), WEST => (0.5, 0))
    P2 = Dict(NORTH => (0, -0.3), EAST => (-0.3, 0), SOUTH => (0, 0.3), WEST => (0.3, 0))
    P3 = Dict(NORTH => (0, 0.3), EAST => (0.3, 0), SOUTH => (0, -0.3), WEST => (-0.3, 0))
    P4 = Dict(NORTH => (0, 0.5), EAST => (0.5, 0), SOUTH => (0, -0.5), WEST => (-0.5, 0))

    grid = get_grid(network)
    h, w = size(grid)
    X_lines, Y_lines = Float64[], Float64[]
    X_limits, Y_limits = Float64[], Float64[]
    X_stations, Y_stations = Float64[], Float64[]

    stations = station_positions(agents)

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

            if (i, j) in stations
                append!(X_stations, j .+ 0.7 * [-0.5, 0.5, 0.5, -0.5, -0.5, NaN])
                append!(Y_stations, (h - i + 1) .+ 0.7 * [-0.5, -0.5, 0.5, 0.5, -0.5, NaN])
            end
        end
    end
    return (X_lines, Y_lines), (X_limits, Y_limits), (X_stations, Y_stations)
end

function agent_coords(network::FlatlandNetwork, solution, t)
    h, w = get_height(network), get_width(network)
    XY = Tuple{Float64,Float64}[]
    M, A = Symbol[], Int[]

    for a in 1:length(solution)
        path = solution[a]
        for (s, v) in path
            if s == t
                i, j, direction, kind = get_label(network, v)
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
    A = Makie.Observable(Int[])
    XY = Makie.Observable(Point2f[])
    M = Makie.Observable(Symbol[])
    Makie.scatter!(ax, XY; marker=:rect, color=:red, markersize=30)
    Makie.scatter!(ax, XY; marker=M, color="white", markersize=15)
    Makie.text!(ax, Makie.@lift(string.($A)); position=XY, color="black", align=(:center, :center))
    return A, XY, M
end

function plot_network(network::FlatlandNetwork)
    xy_lines, xy_limits, xy_stations = rail_coords(network)
    h, w = get_height(network), get_width(network)
    fig = Makie.Figure(; figure_padding=1)
    ax = Makie.Axis(fig[1, 1]; xticks=1:w, yticks=(1:h, string.(h:-1:1)))
    Makie.lines!(ax, xy_lines...; color="black")
    ax.aspect = Makie.DataAspect()
    Makie.scatter!(ax, xy_limits...; color="black", marker=:cross)
    Makie.lines!(ax, xy_stations...; color="black")
    Makie.colsize!(fig.layout, 1, Makie.Aspect(1, 1.0))
    Makie.resize_to_layout!(fig)
    A, XY, M = add_agents!(ax)
    return fig, (A, XY, M)
end
