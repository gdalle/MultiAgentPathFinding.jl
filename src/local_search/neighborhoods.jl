function random_neighborhood(mapf::MAPF, neighborhood_size)
    return sample(1:nb_agents(mapf), neighborhood_size; replace=false)
end
