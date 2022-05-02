function display_map(map_matrix::Matrix{Char}; path=nothing)
    height, width = size(map_matrix)
    map_colors = Matrix{RGB}(undef, height, width)
    for i in 1:height, j in 1:width
        c = map_matrix[i, j]
        if c == '.'
            x = RGB(1.0, 1.0, 1.0)
        elseif c == 'G'
            x = RGB(1.0, 1.0, 1.0)
        elseif c == 'S'
            x = RGB(0.4, 0.4, 0.0)
        elseif c == 'W'
            x = RGB(0.0, 0.0, 1.0)
        elseif c == 'T'
            x = RGB(0.0, 0.7, 0.0)
        elseif c == '@'
            x = RGB(0.0, 0.0, 0.0)
        elseif c == 'O'
            x = RGB(0.0, 0.0, 0.0)
        else
            x = RGB(0.0, 0.0, 0.0)
        end
        map_colors[i, j] = x
    end
    if !isnothing(path)
        g = GridGraph(map_matrix)
        for ed in path
            s, d = src(ed), dst(ed)
            (is, js) = node_coord(g, s)
            (id, jd) = node_coord(g, d)
            map_colors[is, js] = RGB(1., 0., 0.)
            map_colors[id, jd] = RGB(1., 0., 0.)
        end
    end
    return map_colors
end
