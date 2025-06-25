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

function Base.show(io::IO, vc::VertexConflict)
    (; t, v, a1, a2) = vc
    return print(io, "Conflict at time $t on vertex $v between agents $a1 and $a2")
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

function Base.show(io::IO, ec::EdgeConflict)
    (; t, u, v, a1, a2) = ec
    return print(io, "Conflict at time $t on edge $((u, v)) between agents $a1 and $a2")
end

"""
$(TYPEDSIGNATURES)

Find a conflict in `solution` for `mapf`.
"""
function find_conflict(solution::Solution, mapf::MAPF)
    reservation = Reservation(solution, mapf)
    (; multi_occupied_vertices, multi_occupied_edges) = reservation
    if !isempty(multi_occupied_vertices)
        ((t, v), agents) = first(multi_occupied_vertices)
        return VertexConflict(; t, v, a1=agents[1], a2=agents[2])
    elseif !isempty(multi_occupied_edges)
        ((t, u, v), agents) = first(multi_occupied_edges)
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
    (; multi_occupied_vertices, multi_occupied_edges) = reservation
    # TODO: define formula
    nb_vertex_conflicts = sum(length, values(multi_occupied_vertices); init=0)
    nb_edge_conflicts = sum(length, values(multi_occupied_edges); init=0)
    return nb_vertex_conflicts + nb_edge_conflicts
end

"""
$(TYPEDSIGNATURES)

Check whether `solution` is feasible when agents are considered separately.
"""
function is_individually_feasible(solution::Solution, mapf::MAPF; verbose=false)
    (; g, departures, arrivals) = mapf
    (; paths) = solution
    for a in 1:nb_agents(mapf)
        if !(a in eachindex(paths))
            verbose && @warn "No path for agent $a"
            return false
        end
        if isempty(paths[a])
            verbose && @warn "Empty path for agent $a"
            return false
        elseif first(paths[a]) != departures[a]
            verbose && @warn "Wrong departure vertex for agent $a"
            return false
        elseif last(paths[a]) != arrivals[a]
            verbose && @warn "Wrong arrival vertex for agent $a"
            return false
        elseif !exists_in_graph(paths[a], g)
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
