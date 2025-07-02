using MultiAgentPathFinding
using CairoMakie, Colors
using Test

instance = "empty-8-8"
scen_type = "even"
type_id = 1
agents = 14
scen = BenchmarkScenario(; instance, scen_type, type_id, agents)

mapf = MAPF(scen)
grid = read_benchmark_map(instance)
graph, coord_to_vertex, vertex_to_coord = parse_benchmark_map(grid)

sol_indep = independent_dijkstra(mapf)
sol_coop = cooperative_astar(mapf)
sol_opt = Solution(scen; check=true)

for k in eachindex(sol_opt.paths, sol_coop.paths)
    path_coop = sol_coop.paths[k]
    path_opt = sol_opt.paths[k]
    @show k, path_coop == path_opt
end

for a1 in 1:agents, a2 in 1:agents
    a1 != a1 || continue
    p1 = sol_coop.paths[a1]
    p2 = sol_coop.paths[a2]
    length(p1) <= length(p2) || continue
    for t in 1:(length(p1) - 1)
        u1, u2 = p1[t], p2[t]
        v1, v2 = p1[t + 1], p2[t + 1]
        if u1 == u2 || v1 == v2 || (u1 == v2 && u2 == v1)
            @show a1, a2
        end
    end
    for t in length(p1):length(p2)
        u1 = p1[end]
        u2 = p2[t]
        if u1 == u2
            @show a1, a2
        end
    end
end

for (p1, p2) in zip(sol_opt.paths, sol_coop.paths)
    if p1 != p2
        @show p1 p2
        println()
    end
end

@test !is_feasible(sol_indep, mapf)
@test is_feasible(sol_coop, mapf)
@test is_feasible(sol_opt, mapf)

f_indep = sum_of_costs(sol_indep, mapf)
f_coop = sum_of_costs(sol_coop, mapf)
f_opt = sum_of_costs(sol_opt, mapf)

@test f_indep <= f_coop
@test f_indep <= f_opt
@test f_opt <= f_coop

agent_colors = distinguishable_colors(
    agents,
    [colorant"white", colorant"black"];
    dropseed=true,
    lchoices=range(70; stop=90, length=15),
)

sol = sol_coop
T = maximum(length, sol.paths)
paths_extended = stack([
    vcat(path, fill(path[end], T - length(path))) for path in sol.paths
])
paths_extended_coord = map(paths_extended) do v
    i, j = vertex_to_coord[v]
    x, y = j, h - i + 1
end

h, w = size(grid)
t = Observable(1.0)
t0 = @lift floor(Int, $t)
t1 = @lift ifelse($t == $t0, $t0 + 1, ceil(Int, $t))
pos0 = @lift paths_extended_coord[$t0, :]
pos1 = @lift paths_extended_coord[$t1, :]
x0 = @lift last.($pos0)
x1 = @lift last.($pos1)
y0 = @lift first.($pos0)
y1 = @lift first.($pos1)
x = @lift ($t - $t0) .* $x1 .+ ($t1 - $t) .* $x0
y = @lift ($t - $t0) .* $y1 .+ ($t1 - $t) .* $y0

text = string.(1:agents)

fig = Figure()
ax = Axis(fig[1, 1]; aspect=1.0, xticks=1:w, yticks=1:h, limits=((0, w + 1), (0, h + 1)))
tl = textlabel!(
    ax,
    x,
    y;
    text,
    background_color=agent_colors,
    shape=Circle(Point2f(0), 1.0f0),
    shape_limits=Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2)),
    keep_aspect=true,
)
fig

framerate = 20
timesteps = range(1, T - 1e-3; step=1 / framerate)

record(fig, "time_animation.mp4", timesteps; framerate) do _t
    t[] = _t
end
