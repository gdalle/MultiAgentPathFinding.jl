## Graph subtyping

struct GridGraph <: AbstractGraph{Int}
    grid::Matrix{Char}
end

is_passable(c::Char) = (c == '.') || (c == 'G') || (c == 'S')

function node_index(g::GridGraph, i::Integer, j::Integer)
    n, m = size(g)
    if (1 <= i <= n) && (1 <= j <= m)
        v = (i - 1) * m + (j - 1) + 1  # enumerate row by row
        return v
    else
        return 0
    end
end

function node_coord(g::GridGraph, v::Integer)
    n, m = size(g)
    if 1 <= v <= n * m
        i = (v - 1) ÷ m + 1
        j = (v - 1) % m + 1
        return i, j
    else
        return (0, 0)
    end
end

Base.eltype(::GridGraph) = Int
Graphs.edgetype(::GridGraph) = Graphs.SimpleEdge{Int}

Graphs.is_directed(::GridGraph) = true
Graphs.is_directed(::Type{<:GridGraph}) = true

Base.size(g::GridGraph, args...) = size(g.grid, args...)

Graphs.nv(g::GridGraph) = prod(size(g))
Graphs.vertices(g::GridGraph) = 1:nv(g)
Graphs.has_vertex(g::GridGraph, v::Integer) = 1 <= v <= nv(g)

function Graphs.ne(g::GridGraph)
    m = 0
    for s in vertices(g)
        for d in outneighbors(g, s)
            if s < d
                m += 1
            end
        end
    end
    return m
end

function Graphs.has_edge(g::GridGraph, s::Integer, d::Integer)
    if has_vertex(g, s) && has_vertex(g, d) && (d != s)
        is, js = node_coord(g, s)
        id, jd = node_coord(g, d)
        if !is_passable(g.grid[is, js]) || !is_passable(g.grid[id, jd])
            return false
        elseif (abs(is - id) > 1) || (abs(js - jd) > 1)
            return false
        elseif (is == id) || (js == jd)
            return true
        else
            return is_passable(g.grid[is, jd]) || is_passable(g.grid[id, js])
        end
    else
        return false
    end
end

function Graphs.outneighbors(g::GridGraph, s::Integer)
    n, m = size(g)
    i, j = node_coord(g, s)
    possible_neighbors = (
        (i - 1, j - 1),
        (i - 1, j),
        (i - 1, j + 1),
        (i, j - 1),
        (i, j + 1),
        (i + 1, j - 1),
        (i + 1, j),
        (i + 1, j + 1),
    )  # listed in ascending index order!
    neighbors = (
        node_index(g, id, jd) for (id, jd) in possible_neighbors if
        (1 <= id <= n) && (1 <= jd <= m) && has_edge(g, s, node_index(g, id, jd))
    )
    return neighbors
end

Graphs.inneighbors(g::GridGraph, d::Integer) = outneighbors(g, d)

function Graphs.edges(g::GridGraph)
    return (Graphs.SimpleEdge(s, d) for s in vertices(g) for d in outneighbors(g, s))
end

function Graphs.weights(g::GridGraph)
    E = edges(g)
    I = [src(ed) for ed in E]
    J = [dst(ed) for ed in E]
    V = Float64[]
    for ed in E
        s, d = src(ed), dst(ed)
        is, js = node_coord(g, s)
        id, jd = node_coord(g, d)
        if (is == id) || (js == jd)
            push!(V, 1.)
        else
            push!(V, √2)
        end
    end
    w = sparse(I, J, V, nv(g), nv(g))
    return w
end

## Shortest path functions

function shortest_path_grid(g::GridGraph, (is, js), (id, jd))
    # Compute the shortest path
    w = weights(g)
    s = node_index(g, is, js)
    d = node_index(g, id, jd)
    heuristic(v) = sum(abs, (id, jd) .- node_coord(g, v))
    path = a_star(g, s, d, w, heuristic)
    return path
end

Graphs.reverse(g::GridGraph) = g
