function read_benchmark_map(map_path::AbstractString)
    lines = open(map_path, "r") do file
        readlines(file)
    end
    height_line = split(lines[2])
    width_line = split(lines[3])
    height = parse(Int, height_line[2])
    width = parse(Int, width_line[2])
    char_matrix = Matrix{Char}(undef, height, width)
    for i in 1:height
        line = lines[4 + i]
        for j in 1:width
            char_matrix[i, j] = line[j]
        end
    end
    return char_matrix
end

function read_benchmark_scenario(scen_path::AbstractString; map_path=nothing)
    lines = open(scen_path, "r") do file
        readlines(file)
    end
    scenario = DataFrame(;
        bucket=Int[],
        map=String[],
        width=Int[],
        height=Int[],
        start_i=Int[],
        start_j=Int[],
        goal_i=Int[],
        goal_j=Int[],
        optimal_length=Float64[],
    )
    for line in @view lines[2:end]
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

        start_i = start_y + 1
        start_j = start_x + 1
        goal_i = goal_y + 1
        goal_j = goal_x + 1

        line_tup = (
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
        push!(scenario, line_tup)
    end
    return scenario
end
