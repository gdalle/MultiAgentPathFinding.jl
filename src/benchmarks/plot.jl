function get_point(vertex_to_coord::Vector, v::Integer; h)
    i, j = vertex_to_coord[v]
    x, y = j, h - i + 1  # translate from matrix to plot system
    return Point2d(x - 0.5, y - 0.5)  # align with heatmap
end

"""
$(TYPEDSIGNATURES)

Visualize a solution for one of the grid benchmark instances at a given time step.

If a `solution` and `video_path` are provided, the entire animation will be recorded and saved there.

!!! warning
    To use this function, first load a [Makie.jl](https://github.com/MakieOrg/Makie.jl) backend, like CairoMakie.jl (for static visualization / animation recording) or GLMakie.jl (for interactive exploration).
"""
function plot_mapf(
    scen::BenchmarkScenario,
    solution::Union{Solution,Nothing}=nothing;
    time::Integer=1,
    video_path::Union{String,Nothing}=nothing,
    frames_per_move::Integer=20,
    frames_per_second::Integer=20,
    display_targets::Bool=true,
)
    (; instance, scen_type, type_id) = scen
    grid = read_benchmark_map(instance)
    h, w = size(grid)
    (; graph, coord_to_vertex, vertex_to_coord) = parse_benchmark_map(grid)
    grid_binary = passable_cell.(grid)
    mapf = MAPF(scen)
    (; departures, arrivals) = mapf

    fig = Figure()
    ax = Axis(
        fig[1, 1];
        title="MAPF instance $instance",
        subtitle="Scenario $scen_type-$type_id",
        aspect=DataAspect(),
        limits=((0, w), (0, h)),
    )

    colsize!(fig.layout, 1, Aspect(1, 1.0))
    resize_to_layout!(fig)

    if sum(grid_binary) < prod(size(grid_binary))
        image!(ax, rotr90(grid_binary); interpolate=false)
    end

    grid_lims = vcat(
        [(Point2d(0, y), Point2d(w, y)) for y in 0:h],
        [(Point2d(x, 0), Point2d(x, h)) for x in 0:w],
    )
    linesegments!(ax, grid_lims; linewidth=0.5, color=:gray)

    if isnothing(solution)
        return fig
    end

    agents = length(solution.paths)
    T = maximum(length, solution.paths)

    paths_extended = stack([
        vcat(path, fill(path[end], T - length(path))) for path in solution.paths
    ])

    get_point_partial(v) = get_point(vertex_to_coord, v; h)
    paths_extended_coord = map(get_point_partial, paths_extended)
    arrivals_coord = map(get_point_partial, arrivals)

    sl_t = Slider(fig[2, 1]; range=1:0.1:T, startvalue=time, update_while_dragging=true)

    t = sl_t.value
    t0 = @lift floor(Int, $t)
    t1 = @lift ifelse($t == $t0, $t0 + 1, ceil(Int, $t))
    pos0 = @lift paths_extended_coord[$t0, :]
    pos1 = @lift paths_extended_coord[min($t1, end), :]
    pos = @lift ($t - $t0) .* $pos1 .+ ($t1 - $t) .* $pos0
    time_label = @lift string("Time: ", @sprintf("%.2f", $t))

    agent_colors = distinguishable_colors(
        agents,
        [colorant"white", colorant"black"];
        dropseed=true,
        lchoices=range(60; stop=100, length=15),
    )

    scatter!(
        ax,
        pos;  # 
        color=agent_colors,
        marker=Circle,
        markersize=0.8,
        markerspace=:data,
    )
    if display_targets
        scatter!(
            ax,
            arrivals_coord;  # 
            color=:white,
            marker=Circle,
            markersize=0.9,
            markerspace=:data,
            glowcolor=agent_colors,
            glowwidth=2,
        )
    end
    scatter!(
        ax,
        pos;  # 
        color=agent_colors,
        marker=Circle,
        markersize=0.8,
        markerspace=:data,
    )
    text!(
        ax,
        pos;
        text=map(string, 1:agents),
        fontsize=0.4,
        align=(:center, :center),
        markerspace=:data,
    )

    Label(fig[2, 1], time_label; tellwidth=false, tellheight=true)

    timesteps = range(1, T; step=1 / frames_per_move)

    if !isnothing(video_path)
        record(fig, video_path, timesteps; frames_per_second) do _t
            sl_t.value = _t
        end
        sl_t.value = time
    end

    return fig
end
