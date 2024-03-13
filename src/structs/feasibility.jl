
"""
$(TYPEDEF)

Temporal vertex conflict between two agents (for debugging purposes).

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct VertexConflict
    "time"
    t::Int
    "vertex"
    v::Int
    "first agent"
    a1::Int
    "second agent"
    a2::Int
end

"""
$(TYPEDEF)

Temporal edge conflict between two agents (for debugging purposes).

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct EdgeConflict
    "time"
    t::Int
    "edge source"
    u::Int
    "edge destination"
    v::Int
    "first agent"
    a1::Int
    "second agent"
    a2::Int
end

"""
$(TYPEDSIGNATURES)

Find a conflict in `solution` for `mapf`.
"""
function find_conflict(solution::Solution, mapf::MAPF)
    reservation = Reservation(solution, mapf)
    if !isempty(reservation.multi_occupied_vertices)
        ((t, v), agents) = first(reservation.multi_occupied_vertices)
        return VertexConflict(; t, v, a1=agents[1], a2=agents[2])
    elseif !isempty(reservation.multi_occupied_edges)
        ((t, u, v), agents) = first(reservation.multi_occupied_edges)
        return EdgeConflict(; t, u, v, a1=agents[1], a2=agents[2])
    else
        return nothing
    end
end

"""
$(TYPEDSIGNATURES)

Count the number of conflicts in `solution` for `mapf`.
"""
function count_conflicts(solution::Solution, mapf::MAPF)
    reservation = Reservation(solution, mapf)
    # TODO: define formula
    nb_vertex_conflicts = sum(length, values(reservation.multi_occupied_vertices); init=0)
    nb_edge_conflicts = sum(length, values(reservation.multi_occupied_edges); init=0)
    return nb_vertex_conflicts + nb_edge_conflicts
end

"""
$(TYPEDSIGNATURES)

Check whether `solution` is feasible when agents are considered separately.
"""
function is_individually_feasible(solution::Solution, mapf::MAPF; verbose=false)
    for a in 1:nb_agents(mapf)
        if !haskey(solution.timed_paths, a)
            verbose && @warn "No path for agent $a"
            return false
        end
        timed_path = solution.timed_paths[a]
        if isempty(timed_path)
            verbose && @warn "Empty path for agent $a"
            return false
        elseif departure_time(timed_path) != mapf.departure_times[a]
            verbose && @warn "Wrong departure time for agent $a"
            return false
        elseif departure_vertex(timed_path) != mapf.departures[a]
            verbose && @warn "Wrong departure vertex for agent $a"
            return false
        elseif arrival_vertex(timed_path) != mapf.arrivals[a]
            verbose && @warn "Wrong arrival vertex for agent $a"
            return false
        elseif !exists_in_graph(timed_path, mapf.g)
            verbose && @warn "Path of agent $a does not exist in graph"
            return false
        end
    end
    return true
end

"""
$(TYPEDSIGNATURES)

Check whether `solution` contains any conflicts between agents.
"""
function is_collectively_feasible(solution::Solution, mapf::MAPF; verbose=false)
    conflict = find_conflict(solution, mapf)
    if !isnothing(conflict)
        verbose && @warn "Conflict in solution" conflict
        return false
    else
        return true
    end
end

"""
$(TYPEDSIGNATURES)

Check whether `solution` is both individually and collectively feasible (correct paths and no conflicts).
"""
function is_feasible(solution::Solution, mapf::MAPF; verbose=false)
    return is_individually_feasible(solution, mapf; verbose) &&
           is_collectively_feasible(solution, mapf; verbose)
end
