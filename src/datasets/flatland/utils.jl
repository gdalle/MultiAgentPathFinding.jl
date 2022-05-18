function reverse_direction(d::Integer)
    if d == NORTH
        return SOUTH
    elseif d == SOUTH
        return NORTH
    elseif d == WEST
        return EAST
    elseif d == EAST
        return WEST
    else
        error("Reverse direction for $d not defined")
    end
end

## Grid utilities

function neighbor_cell(i::Integer, j::Integer, out_direction::Integer)
    if out_direction == NORTH
        return (i - 1, j)
    elseif out_direction == EAST
        return (i, j + 1)
    elseif out_direction == SOUTH
        return (i + 1, j)
    elseif out_direction == WEST
        return (i, j - 1)
    else
        error("Out-direction $out_direction is not valid")
    end
end

function transition_exists(
    transition_map::String, in_direction::Integer, out_direction::Integer
)
    return transition_map[4(in_direction - 1) + out_direction] == '1'
end

function direction_exists(transition_map::String, in_direction::Integer)
    return any(
        transition_exists(transition_map, in_direction, out_direction) for
        out_direction in CARDINAL_POINTS
    )
end

## Vertex utilities

function vertices_on_cell(g::FlatlandGraph, (i, j, direction, kind))
    return (
        get_vertex(g, (i, j, direction, REAL)) for
        direction in CARDINAL_POINTS if haskey(g, (i, j, direction, REAL))
    )
end

function mirror_vertex(g::FlatlandGraph, (i, j, direction, kind))
    if kind == REAL
        i2, j2 = neighbor_cell(i, j, reverse_direction(direction))
        return get_vertex(g, (i2, j2, reverse_direction(direction), REAL))
    end
end

vertices_on_cell(g::FlatlandGraph, v::Integer) = vertices_on_cell(g, get_label(g, v))
mirror_vertex(g::FlatlandGraph, v::Integer) = mirror_vertex(g, get_label(g, v))
is_real_vertex(g::FlatlandGraph, v::Integer) = last(get_label(g, v)) == REAL
