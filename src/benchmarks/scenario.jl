"""
$(TYPEDSIGNATURES)

List available scenarios from the benchmark set.
"""
function list_scenario_names(scen_type::String)
    @assert scen_type in ("random", "even")
    return readdir(joinpath(@datadep_str("mapf-scen-$scen_type"), "scen-$scen_type"))
end

"""
$(TYPEDSIGNATURES)

Return the map associated with a benchmark scenario.
"""
function map_from_scenario(scenario_name::AbstractString)
    name = join(split(split(scenario_name, '.')[1], '-')[begin:(end - 2)], '-')
    return "$name.map"
end

"""
$(TYPEDSIGNATURES)

List the scenarios associated with a benchmark map.
"""
function scenarios_from_map(map_name::AbstractString, scen_type::String)
    name = split(map_name, '.')[1]
    return filter(list_scenario_names(scen_type)) do scenario_name
        startswith(scenario_name, name) && scenario_name[length(name) + 1] == '-'
    end
end

"""
$(TYPEDEF)

Encode one agent of a MAPF scenario.

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct MAPFBenchmarkAgent
    index::Int
    bucket::Int
    map_path::String
    width::Int
    height::Int
    start_i::Int
    start_j::Int
    goal_i::Int
    goal_j::Int
    optimal_length::Float64
end

"""
$(TYPEDSIGNATURES)

Read a scenario from a text file, and check that it corresponds to a given map.

Returns a `Vector{MAPFBenchmarkAgent}`.
"""
function read_benchmark_scenario(scenario_name::AbstractString, map_name::AbstractString)
    scenario_path = ""
    scenario_type = split(scenario_name, '-')[end - 1]
    if scenario_type == "random"
        scenario_path = joinpath(datadep"mapf-scen-random", "scen-random", scenario_name)
    elseif scenario_type == "even"
        scenario_path = joinpath(datadep"mapf-scen-even", "scen-even", scenario_name)
    else
        error("Invalid scenario")
    end
    lines = open(scenario_path, "r") do file
        readlines(file)
    end
    scenario = MAPFBenchmarkAgent[]
    for (l, line) in enumerate(view(lines, 2:length(lines)))
        line_split = split(line, "\t")
        bucket = parse(Int, line_split[1]) + 1
        map_path = line_split[2]
        width = parse(Int, line_split[3])
        height = parse(Int, line_split[4])
        start_x = parse(Int, line_split[5])
        start_y = parse(Int, line_split[6])
        goal_x = parse(Int, line_split[7])
        goal_y = parse(Int, line_split[8])
        optimal_length = parse(Float64, line_split[9])
        @assert endswith(map_name, map_path)
        start_i = start_y + 1
        start_j = start_x + 1
        goal_i = goal_y + 1
        goal_j = goal_x + 1
        problem = MAPFBenchmarkAgent(;
            index=l,
            bucket=bucket,
            map_path=map_path,
            width=width,
            height=height,
            start_i=start_i,
            start_j=start_j,
            goal_i=goal_i,
            goal_j=goal_j,
            optimal_length=optimal_length,
        )
        push!(scenario, problem)
    end
    return scenario
end

"""
$(TYPEDSIGNATURES)

Turn a scenario into vectors of departure coordinates and a vector of arrival coordinates.
"""
function parse_benchmark_scenario(scenario::Vector{MAPFBenchmarkAgent})
    A = length(scenario)
    departure_coords = Vector{Tuple{Int,Int}}(undef, A)
    arrival_coords = Vector{Tuple{Int,Int}}(undef, A)
    for a in 1:A
        problem = scenario[a]
        is, js = problem.start_i, problem.start_j
        id, jd = problem.goal_i, problem.goal_j
        departure_coords[a] = (is, js)
        arrival_coords[a] = (id, jd)
    end
    @assert length(unique(departure_coords)) == length(departure_coords)
    @assert length(unique(arrival_coords)) == length(arrival_coords)
    return departure_coords, arrival_coords
end
