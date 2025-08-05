"""
    list_instances()

List available maps from the benchmark set.
"""
function list_instances()
    return map(s -> chopsuffix(s, ".map"), readdir(datadep"mapf-map"))
end

"""
    read_benchmark_map(instance_name::AbstractString)

Read a map from an automatically downloaded text file.

Return a `Matrix{Char}` where each character describes the type of one cell.
"""
function read_benchmark_map(instance_name::AbstractString)
    map_path = joinpath(datadep"mapf-map", "$instance_name.map")
    lines = open(map_path, "r") do file
        readlines(file)
    end
    height_line = split(lines[2])
    height = parse(Int, height_line[2])
    width_line = split(lines[3])
    width = parse(Int, width_line[2])
    grid = Matrix{Char}(undef, height, width)
    for i in 1:height
        line = lines[4 + i]
        for j in 1:width
            grid[i, j] = line[j]
        end
    end
    return grid
end

"""
    passable_cell(c::Char)

Determine if a cell is passable terrain or not.
"""
passable_cell(c::Bool) = !c
passable_cell(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

"""
    parse_benchmark_map(grid::AbstractMatrix)

Create a sparse grid graph from a map specified as a matrix (e.g. obtained from `read_benchmark_map`).
Each element of the grid can be either

- a `Bool`, in which case `false` denotes passable terrain and `true` denotes an obstacle
- a `Char`, in which case `'.'` denotes passable terrain and `'@'` denotes an obstacle

Return a named tuple `(; graph, coord_to_vertex, vertex_to_coord)`, where the last two items map between integer graph vertices `v` and coordinate tuples `(i, j)` (with `(1, 1)` as the upper-left corner).
"""
function parse_benchmark_map(grid::AbstractMatrix; allow_diagonal_moves::Bool=false)
    h, w = size(grid)
    passable = passable_cell.(grid)

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
                if diag && !allow_diagonal_moves
                    continue
                else
                    weight = diag ? sqrt(2.0) : 1.0
                    if s <= d
                        push!(sources, s)
                        push!(destinations, d)
                        push!(weights, weight)
                    end
                end
            end
        end
    end

    graph = SimpleWeightedGraph(sources, destinations, weights; combine=max)
    vertex_to_coord = Vector{Tuple{Int,Int}}(undef, nv(graph))
    for ((i, j), v) in pairs(coord_to_vertex)
        vertex_to_coord[v] = (i, j)
    end
    return (; graph, coord_to_vertex, vertex_to_coord)
end

"""
    cell_color(c::Char)

Give a color object corresponding to the type of cell.

To visualize a map in VSCode, just run `cell_color.(grid)` in the REPL.
"""
function cell_color(c::Char)
    if c == '.'  # empty => white
        return colorant"white"
    elseif c == 'G'  # empty => white
        return colorant"white"
        # COV_EXCL_START
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
    # COV_EXCL_STOP
end
