## Graph subtyping

struct GridGraph <: AbstractGraph{Int}
    grid::Matrix{Char}
    nv::Int
    ne::Int
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

Base.size(g::GridGraph, args...) = size(g.cell_costs, args...)
height(g::GridGraph) = size(g, 1)
width(g::GridGraph) = size(g, 2)

Graphs.nv(g::GridGraph) = g.nv
Graphs.ne(g::GridGraph) = g.ne
Graphs.vertices(g::GridGraph) = 1:nv(g)
Graphs.has_vertex(g::GridGraph, v::Integer) = 1 <= v <= nv(g)

function Graphs.has_edge(g::GridGraph, s::Integer, d::Integer)
    if has_vertex(g, s) && has_vertex(g, d)
        is, js = node_coord(g, s)
        id, jd = node_coord(g, d)
        return (s != d) && (abs(is - id) <= 1) && (abs(js - jd) <= 1)  # 8 neighbors max
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
        node_index(g, id, jd) for (id, jd) in possible_neighbors if (1 <= id <= n) && (1 <= jd <= m)
    )
    return neighbors
end

Graphs.inneighbors(g::GridGraph, d::Integer) = outneighbors(g, d)

function Graphs.edges(g::GridGraph)
    return (
        Graphs.SimpleEdge(s, d) for s in vertices(g) for d in outneighbors(g, s)
    )
end

function Graphs.weights(g::GridGraph)
    E = edges(g)
    I = [src(e) for e in E]
    J = [dst(e) for e in E]
    V = Float16[]
    for e in E
        d = dst(e)
        id, jd = node_coord(g, d)
        cost = g.cell_costs[id, jd]
        push!(V, cost)
    end
    W = sparse(I, J, V, nv(g), nv(g))
    return W
end

## Shortest path functions

function compute_shorest_path_grid(g::GridGraph)
    # Compute the shortest path
    c = weights(g)
    path = a_star(g, 1, nv(g), c)
    # Save the zero_one_path
    zero_one_path = zeros(UInt8, size(g))
    zero_one_path[1,1] = 1 #start node
    for edge in path
        i, j = node_coord(g, dst(edge))
        zero_one_path[i, j] =  one(UInt8)
    end
    return zero_one_path
end


function compute_path_cost(;weights::Matrix{Float16}, zero_one_path::Matrix{UInt8})
    grid_size = size(weights)
    return sum([weights[i,j]*zero_one_path[i,j] for i = 1:grid_size[1] for j = 1:grid_size[2]])
end

function grid_to_vector(label::Matrix{T}) where T
    n, m = size(label)
    vec_label = zeros(T, n*m)
    for i = 1:n
        for j = 1:m
            index = (i - 1) * m + (j - 1) + 1
            vec_label[index] = label[i,j]
        end
    end
    return vec_label
end

function vector_to_grid(vec_label::Vector{T}) where T
    nm = length(vec_label)
    c = Int(sqrt(nm))
    grid = zeros(T, (c, c)) #caution square grid
    for v = 1:nm
        i = (v - 1) ÷ c + 1
        j = (v - 1) % c + 1
        grid[i,j] = vec_label[v]
    end
    return grid
end

function warcraft_shortest_path(θ; g::GridGraph)
    Ic = [src(e) for e in edges(g)]
    Jc = [dst(e) for e in edges(g)]
    Vc = Float16[]
    for e in edges(g)
        d = dst(e)
        cost = -θ[d] #stack vector
        push!(Vc, cost)
    end
    c = sparse(Ic, Jc, Vc, nv(g), nv(g))

    path = a_star(g, 1, nv(g), c)
    y =  zeros(UInt8, nv(g))
    y[1] = 1 #start
    for edge in path
        d = dst(edge)
        y[d] = 1
    end
    return y
end
