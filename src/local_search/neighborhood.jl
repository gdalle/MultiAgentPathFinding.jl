function random_neighborhood(mapf::MAPF, neighborhood_size::Integer)
    return sample(1:nb_agents(mapf), neighborhood_size; replace=false)
end

function random_neighborhood_collision_degree(
    solution::Solution, mapf::MAPF, neighborhood_size::Integer
)
    wv = StatsBase.weights(collision_degrees(solution, mapf) .+ 1)
    return sample(1:nb_agents(mapf), wv, neighborhood_size; replace=false)
end

function conflicting_neighborhood(solution::Solution, mapf::MAPF)
    A = nb_agents(mapf)
    neighborhood = Set{Int}()
    for a in 1:A
        for b in 1:(a - 1)
            if have_conflict(a, b, solution, mapf)
                push!(neighborhood, a)
                push!(neighborhood, b)
                break
            end
        end
    end
    return collect(neighborhood)
end
