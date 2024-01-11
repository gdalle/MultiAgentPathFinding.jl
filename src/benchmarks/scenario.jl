
"""
    MAPFBenchmarkProblem

Encode one agent of a MAPF scenario.

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct MAPFBenchmarkProblem
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
    read_benchmark_scenario(scenario_name::AbstractString, map_name::AbstractString)

Read a scenario from a text file, and check that it corresponds to a given map.

Returns a `Vector{MAPFBenchmarkProblem}`.
"""
function read_benchmark_scenario(scenario_name::AbstractString, map_name::AbstractString)
    scenario_path = ""
    if occursin("random", scenario_name)
        scenario_path = joinpath(datadep"mapf-scen-random", "scen-random", scenario_name)
    elseif occursin("even", scenario_name)
        scenario_path = joinpath(datadep"mapf-scen-even", "scen-even", scenario_name)
    else
        error("Invalid scenario")
    end
    lines = open(scenario_path, "r") do file
        readlines(file)
    end
    scenario = MAPFBenchmarkProblem[]
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
        problem = MAPFBenchmarkProblem(;
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
    parse_benchmark_scenario(scenario::Vector{MAPFBenchmarkProblem}, coord_to_vertex::Dict)

Turn a scenario into vectors of departure and arrival vertices.
"""
function parse_benchmark_scenario(
    scenario::Vector{MAPFBenchmarkProblem}, coord_to_vertex::Dict
)
    A = length(scenario)
    departures = Vector{Int}(undef, A)
    arrivals = Vector{Int}(undef, A)
    for a in 1:A
        problem = scenario[a]
        is, js = problem.start_i, problem.start_j
        id, jd = problem.goal_i, problem.goal_j
        s = coord_to_vertex[is, js]
        d = coord_to_vertex[id, jd]
        departures[a] = s
        arrivals[a] = d
    end
    @assert length(unique(departures)) == length(departures)
    @assert length(unique(arrivals)) == length(arrivals)
    return departures, arrivals
end