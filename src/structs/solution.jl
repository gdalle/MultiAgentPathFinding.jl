"""
Solution

Vector of [`TimedPath`](@ref)`s, one for each agent of a [`MAPF`](@ref).
"""
const Solution = Vector{TimedPath}

function solution_to_mat(solution::Solution, mapf::MAPF)
    (; g, edge_indices) = mapf
    V, E = nv(g), ne(g)
    A = nb_agents(mapf)
    I = Int[]
    J = Int[]
    val = Float64[]
    for a in 1:A
        timed_path = solution[a]
        (; path) = timed_path
        K = length(path)
        for k in 1:(K - 1)
            _, v1 = path[k]
            _, v2 = path[k + 1]
            e = edge_indices[v1, v2]
            push!(I, e)
            push!(J, a)
            push!(val, 1.)
        end
    end
    return sparse(I, J, val, E, A)
end

function remove_agents!(solution::Solution, agents, mapf::MAPF)
    backup = Dict(a => solution[a] for a in agents)
    for a in agents
        solution[a] = TimedPath(mapf.sources[a], Int[])
    end
    return backup
end
