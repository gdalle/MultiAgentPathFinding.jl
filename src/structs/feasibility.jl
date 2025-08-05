"""
    VertexConflict

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

function Base.:(==)(vc1::VertexConflict, vc2::VertexConflict)
    return (vc1.t == vc2.t) &&
           (vc1.v == vc2.v) &&
           extrema((vc1.a1, vc1.a2)) == extrema((vc2.a1, vc2.a2))
end

function Base.show(io::IO, vc::VertexConflict)
    (; t, v, a1, a2) = vc
    return print(io, "Conflict at time $t on vertex $v between agents $a1 and $a2")
end

"""
    EdgeConflict

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

function Base.:(==)(ec1::EdgeConflict, ec2::EdgeConflict)
    return (ec1.t == ec2.t) &&
           extrema((ec1.a1, ec1.a2)) == extrema((ec2.a1, ec2.a2)) &&
           extrema((ec1.u, ec1.v)) == extrema((ec2.u, ec2.v))
end

function Base.show(io::IO, ec::EdgeConflict)
    (; t, u, v, a1, a2) = ec
    return print(io, "Conflict at time $t on edge {$u, $v} between agents $a1 and $a2")
end

"""
    find_conflict(solution::Solution, mapf::MAPF)

Find a conflict in `solution` for `mapf`.

Return either `nothing`, a `VertexConflict` or an `EdgeConflict`.
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
    is_individually_feasible(solution::Solution, mapf::MAPF; verbose=false)

Check whether `solution` is feasible when agents are considered separately (i.e. whether each individual path is correct).

Return a `Bool`.
"""
function is_individually_feasible(solution::Solution, mapf::MAPF; verbose=false)
    (; graph, departures, arrivals) = mapf
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
        elseif !exists_in_graph(paths[a], graph)
            verbose && @warn "Path of agent $a does not exist in graph"
            return false
        end
    end
    return true
end

"""
    is_collectively_feasible(solution::Solution, mapf::MAPF; verbose=false)

Check whether `solution` contains any conflicts between agents.

Return a `Bool`.
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
    is_feasible(solution::Solution, mapf::MAPF; verbose=false)

Check whether `solution` is both individually and collectively feasible (correct paths and no conflicts).

Return a `Bool`.
"""
function is_feasible(solution::Solution, mapf::MAPF; verbose=false)
    return is_individually_feasible(solution, mapf; verbose) &&
           is_collectively_feasible(solution, mapf; verbose)
end
