"""
    list_map_names()

List available maps from the benchmark set.
"""
function list_map_names()
    return readdir(datadep"mapf-map")
end

"""
    read_benchmark_map(map_name::AbstractString)

Read a map matrix from a text file.

Returns a `Matrix{Char}`.
"""
function read_benchmark_map(map_name::AbstractString)
    map_path = joinpath(datadep"mapf-map", map_name)
    lines = open(map_path, "r") do file
        readlines(file)
    end
    height_line = split(lines[2])
    height = parse(Int, height_line[2])
    width_line = split(lines[3])
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

passable_cell(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

"""
    parse_benchmark_map(map_matrix::Matrix{Char})

Create a sparse grid graph from a map specified as a matrix of characters.
"""
function parse_benchmark_map(map_matrix::Matrix{Char};)
    h, w = size(map_matrix)
    passable = passable_cell.(map_matrix)

    coord_to_vertex = Dict{Tuple{Int,Int},Int}()
    v = 1
    for j in 1:w, i in 1:h
        passable[i, j] || continue
        coord_to_vertex[i, j] = v
        v += 1
    end

    sources = Int[]
    destinations = Int[]
    weights = Float64[]

    for j in 1:w, i in 1:h
        passable[i, j] || continue
        for Δi in (-1, 0, 1), Δj in (-1, 0, 1)
            still_inside = (1 <= i + Δi <= h) && (1 <= j + Δj <= w)
            if (
                still_inside &&
                passable[i + Δi, j + Δj] &&
                passable[i + Δi, j] &&
                passable[i, j + Δj]
            )
                s = coord_to_vertex[i, j]
                d = coord_to_vertex[i + Δi, j + Δj]
                diag = Δi != 0 && Δj != 0
                weight = diag ? sqrt(2.0) : 1.0
                if s <= w
                    push!(sources, s)
                    push!(destinations, d)
                    push!(weights, weight)
                end
            end
        end
    end

    g = SimpleWeightedGraph(sources, destinations, weights)
    
    return g, coord_to_vertex
end

"""
    benchmark_cell_color(c::Char)

Give a color object corresponding to the type of cell.

To visualize a map in VSCode, just run `cell_color.(map_matrix)` in the REPL.
"""
function benchmark_cell_color(c::Char)
    if c == '.'  # empty => white
        return colorant"white"
    elseif c == 'G'  # empty => white
        return colorant"white"
    elseif c == 'S'  # shallow water => brown
        return colorant"brown"
    elseif c == 'W'  # water => blue
        return colorant"blue"
    elseif c == 'T'  # trees => green
        return colorant"green"
    elseif c == '@'  # wall => black
        return colorant"black"
    elseif c == 'O'  # wall => black
        return colorant"black"
    elseif c == 'H'  # here => red
        return colorant"red"
    else  # ? => black
        return colorant"black"
    end
end
