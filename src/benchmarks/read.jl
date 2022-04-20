function read_map(path)
    lines = open(path, "r") do file
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

function read_scenario(path)
    lines = open(path, "r") do file
        readlines(file)
    end
    scenario = DataFrame(;
        bucket=Int[],
        map=String[],
        width=Int[],
        height=Int[],
        start_x=Int[],
        start_y=Int[],
        goal_x=Int[],
        goal_y=Int[],
        optimal_length=Float64[],
    )
    for line in @view lines[2:end]
        line_split = split(line, "\t")
        line_tup = (
            bucket=parse(Int, line_split[1]) + 1,
            map=line_split[2],
            width=parse(Int, line_split[3]),
            height=parse(Int, line_split[4]),
            start_x=parse(Int, line_split[5]) + 1,
            start_y=parse(Int, line_split[6]) + 1,
            goal_x=parse(Int, line_split[7]) + 1,
            goal_y=parse(Int, line_split[8]) + 1,
            optimal_length=parse(Float64, line_split[9]),
        )
        push!(scenario, line_tup)
    end
    return scenario
end
