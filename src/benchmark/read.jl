"""
    BenchmarkProblem

# Fields
- `index::Int`
- `bucket::Int`
- `map::String`
- `width::Int`
- `height::Int`
- `start_i::Int`
- `start_j::Int`
- `goal_i::Int`
- `goal_j::Int`
- `optimal_length::Float64`
"""
Base.@kwdef struct BenchmarkProblem
    index::Int
    bucket::Int
    map::String
    width::Int
    height::Int
    start_i::Int
    start_j::Int
    goal_i::Int
    goal_j::Int
    optimal_length::Float64
end

"""
    read_benchmark_map(map_path)
"""
function read_benchmark_map(map_path::AbstractString)
    lines = open(map_path, "r") do file
        readlines(file)
    end
    height_line = split(lines[2])
    width_line = split(lines[3])
    height = parse(Int, height_line[2])
    width = parse(Int, width_line[2])
    map_matrix = Matrix{Char}(undef, height, width)
    for i in 1:height
        line = lines[4 + i]
        for j in 1:width
            map_matrix[i, j] = line[j]
        end
    end
    return map_matrix
end

"""
    read_benchmark_scenario(scenario_path, map_path)
"""
function read_benchmark_scenario(scenario_path::AbstractString, map_path::AbstractString)
    lines = open(scenario_path, "r") do file
        readlines(file)
    end

    scenario = BenchmarkProblem[]

    for (l, line) in enumerate(view(lines, 2:length(lines)))
        line_split = split(line, "\t")
        bucket = parse(Int, line_split[1]) + 1
        map = line_split[2]
        width = parse(Int, line_split[3])
        height = parse(Int, line_split[4])
        start_x = parse(Int, line_split[5])
        start_y = parse(Int, line_split[6])
        goal_x = parse(Int, line_split[7])
        goal_y = parse(Int, line_split[8])
        optimal_length = parse(Float64, line_split[9])
        @assert endswith(map_path, map)

        start_i = start_y + 1
        start_j = start_x + 1
        goal_i = goal_y + 1
        goal_j = goal_x + 1

        problem = BenchmarkProblem(;
            index=l,
            bucket=bucket,
            map=map,
            width=width,
            height=height,
            start_i=start_i,
            start_j=start_j,
            goal_i=goal_i,
            goal_j=goal_j,
            optimal_length=optimal_length,
        )
        push!(scenario, problem)
    end

    return scenario
end
