"""
    display_benchmark_mapf(map_matrix::Matrix{Char})
"""
function display_benchmark_map(map_matrix::Matrix{Char})
    height, width = size(map_matrix)
    map_colors = Matrix{RGB}(undef, height, width)
    for i in 1:height, j in 1:width
        c = map_matrix[i, j]
        if c == '.'  # empty => white
            x = RGB(1.0, 1.0, 1.0)
        elseif c == 'G'  # empty => white
            x = RGB(1.0, 1.0, 1.0)
        elseif c == 'S'  # shallow water => brown
            x = RGB(0.4, 0.4, 0.0)
        elseif c == 'W'  # water => blue
            x = RGB(0.0, 0.0, 1.0)
        elseif c == 'T'  # trees => green
            x = RGB(0.0, 0.7, 0.0)
        elseif c == '@'  # wall => black
            x = RGB(0.0, 0.0, 0.0)
        elseif c == 'O'  # wall => black
            x = RGB(0.0, 0.0, 0.0)
        else  # ? => black
            x = RGB(0.0, 0.0, 0.0)
        end
        map_colors[i, j] = x
    end
    fig, ax, plt = image(
        map_colors'; interpolate=false, axis=(aspect=DataAspect(), yreversed=true)
    )
    return fig
end
