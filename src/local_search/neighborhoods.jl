"""
    random_neighborhood(mapf, neighborhood_size)

Return a random subset of agents with a given size.
"""
function random_neighborhood(mapf::MAPF, neighborhood_size)
    safe_neighborhood_size = min(neighborhood_size, nb_agents(mapf))
    return sample(1:nb_agents(mapf), safe_neighborhood_size; replace=false)
end
