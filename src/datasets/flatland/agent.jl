Base.@kwdef mutable struct Agent
    handle::Int
    earliest_departure::Int
    latest_arrival::Int
    initial_position::Tuple{Int,Int}
    initial_direction::Int
    target_position::Tuple{Int,Int}
end

function Agent(pyagent::Py)
    handle = pyconvert(Int, pyagent.handle) + 1
    earliest_departure = pyconvert(Int, pyagent.earliest_departure) + 1
    latest_arrival = pyconvert(Int, pyagent.latest_arrival) + 1
    initial_position = pyconvert(Tuple{Int,Int}, pyagent.initial_position) .+ 1
    initial_direction = pyconvert(Int, pyagent.initial_direction) + 1
    target_position = pyconvert(Tuple{Int,Int}, pyagent.target) .+ 1

    return Agent(;
        handle=handle,
        earliest_departure=earliest_departure,
        latest_arrival=latest_arrival,
        initial_position=initial_position,
        initial_direction=initial_direction,
        target_position=target_position,
    )
end

function initial_label(agent::Agent)
    return (agent.initial_position..., agent.initial_direction, DEPARTURE)
end

function target_label(agent::Agent)
    return (agent.target_position..., NO_DIRECTION, ARRIVAL)
end

function station_positions(agents::AbstractVector{Agent})
    initial_positions = unique(agent.initial_position for agent in agents)
    target_positions = unique(agent.target_position for agent in agents)
    return union(initial_positions, target_positions)
end
