"""
$(TYPEDSIGNATURES)

Visualize a solution for one of the grid benchmark instances at a given time step.

If `video_path isa String`, the entire animation will be recorded and saved there.
"""
function visualize_solution(
    scen::BenchmarkScenario, solution::Solution, time=1; video_path=nothing, framerate=20
)
    (; instance, scen_type, type_id) = scen
    agents = length(solution.paths)
    grid = read_benchmark_map(instance)
    (; graph, coord_to_vertex, vertex_to_coord) = parse_benchmark_map(grid)
    grid_binary = passable_cell.(grid)

    h, w = size(grid)
    T = maximum(length, solution.paths)
    paths_extended = stack([
        vcat(path, fill(path[end], T - length(path))) for path in solution.paths
    ])
    paths_extended_coord = map(paths_extended) do v
        i, j = vertex_to_coord[v]
        x, y = j, h - i + 1
    end

    t = Observable(float(time))
    t0 = @lift floor(Int, $t)
    t1 = @lift ifelse($t == $t0, $t0 + 1, ceil(Int, $t))
    pos0 = @lift paths_extended_coord[$t0, :]
    pos1 = @lift paths_extended_coord[min($t1, end), :]
    x0 = @lift first.($pos0)
    x1 = @lift first.($pos1)
    y0 = @lift last.($pos0)
    y1 = @lift last.($pos1)
    x = @lift ($t - $t0) .* $x1 .+ ($t1 - $t) .* $x0
    y = @lift ($t - $t0) .* $y1 .+ ($t1 - $t) .* $y0
    subtitle = @lift string("Time: ", @sprintf("%.2f", $t - 1))

    agent_colors = distinguishable_colors(
        agents,
        [colorant"white", colorant"black"];
        dropseed=true,
        lchoices=range(60; stop=100, length=15),
    )

    fig = Figure()
    ax = Axis(
        fig[1, 1];
        title="MAPF instance $instance\nScenario $scen_type-$type_id with $agents agents",
        subtitle,
        aspect=1.0,
        limits=((0, w), (0, h)),
    )

    if sum(grid_binary) < prod(size(grid_binary))
        image!(ax, rotr90(grid_binary); interpolate=false)
    end

    tl = textlabel!(
        ax,
        @lift($x .- 0.5),
        @lift($y .- 0.5);
        text=string.(1:agents),
        background_color=agent_colors,
        shape=Circle(Point2f(0), 0.65),
        shape_limits=Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2)),
        keep_aspect=true,
    )

    timesteps = range(1, T; step=1 / 20)

    if video_path !== nothing
        record(fig, video_path, timesteps; framerate) do _t
            t[] = _t
        end
    end

    return fig
end
