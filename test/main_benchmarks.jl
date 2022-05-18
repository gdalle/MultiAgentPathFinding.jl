using GLMakie
using Graphs
using GridGraphs
using MultiAgentPathFinding
using ProgressMeter
Makie.inline!(true)

map_paths = String[]
scenario_paths = String[]
for map_folder in filter(endswith("-map"), readdir("data"))
    scenario_folder = replace(map_folder, "-map" => "-scen")
    for map_file in readdir(joinpath("data", map_folder))
        scenario_file = replace(map_file, ".map" => ".map.scen")
        push!(map_paths, joinpath("data", map_folder, map_file))
        push!(scenario_paths, joinpath("data", scenario_folder, scenario_file))
    end
end

# for (map_path, scenario_path) in zip(map_paths, scenario_paths)
#     map_matrix = read_benchmark_map(map_path);
#     scenario = read_benchmark_scenario(scenario_path);
#     @info "Reading instance $map_path"
#     @showprogress for bucket in unique(scenario[!, :bucket])
#         mapf = benchmark_mapf(map_matrix, scenario; bucket=1);
#     end
# end

map_path = joinpath("data", "dao-map", "brc101d.map")
scenario_path = joinpath("data", "dao-scen", "brc101d.map.scen")

map_matrix = read_benchmark_map(map_path);
scenario = read_benchmark_scenario(scenario_path);

mapf = benchmark_mapf(map_matrix, scenario; bucket=1);
@profview benchmark_mapf(map_matrix, scenario; bucket=1)

display_benchmark_map(map_matrix)

@profview independent_dijkstra(mapf)
@profview independent_astar(mapf; show_progress=true)
