using Base.Threads
using MultiAgentPathFinding
using ProgressMeter
using Test

for map_folder in filter(endswith("-map"), readdir(data_dir; join=true))
    map_paths = readdir(map_folder; join=true)
    prog = Progress(length(map_paths); desc="Reading $(last(splitpath(map_folder)))")
    @threads for map_path in map_paths
        next!(prog)
        scenario_path = replace(map_path, "-map" => "-scen", ".map" => ".map.scen")
        mapf = benchmark_mapf(map_path, scenario_path; buckets=1:typemax(Int))
    end
end
