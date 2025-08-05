struct MissingScenarioError <: Exception
    msg::String
end

"""
    BenchmarkScenario

Identify a specific benchmark map and scenario from the Sturtevant MAPF benchmarks.

# Fields

$(TYPEDFIELDS)
"""
struct BenchmarkScenario
    "name of the instance"
    instance::String
    "type of scenario, random or even"
    scen_type::String
    "id of the scenario among those with the same type"
    type_id::Int
    "number of agents included"
    agents::Union{Nothing,Int}

    function BenchmarkScenario(;
        instance::String,
        scen_type::String,
        type_id::Int,
        agents::Union{Nothing,Int}=nothing,
    )
        @assert scen_type in ("random", "even")
        return new(instance, scen_type, type_id, agents)
    end
end

"""
    BenchmarkAgent

Encode one agent of a MAPF scenario.

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct BenchmarkAgent
    agent::Int
    bucket::Int
    width::Int
    height::Int
    start_i::Int
    start_j::Int
    goal_i::Int
    goal_j::Int
    optimal_length::Float64
end

"""
    read_benchmark_scenario(scen::BenchmarkScenario)

Read a scenario from an automatically downloaded text file.

Return a `Vector{BenchmarkAgent}`.
"""
function read_benchmark_scenario(scen::BenchmarkScenario)
    (; instance, scen_type, type_id, agents) = scen
    scen_name = "$instance-$scen_type-$type_id"
    scenario_path = joinpath(
        @datadep_str("mapf-scen-$scen_type"), "scen-$scen_type", "$scen_name.scen"
    )
    lines = open(scenario_path, "r") do file
        readlines(file)
    end
    scenario = BenchmarkAgent[]
    for (agent, line) in enumerate(view(lines, 2:length(lines)))
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
        start_i, goal_i = start_y + 1, goal_y + 1  # y axis upside down
        start_j, goal_j = start_x + 1, goal_x + 1
        problem = BenchmarkAgent(;
            agent, bucket, width, height, start_i, start_j, goal_i, goal_j, optimal_length
        )
        push!(scenario, problem)
    end
    if isnothing(agents)
        return scenario
    elseif !(1 <= agents <= length(scenario))
        throw(
            MissingScenarioError(
                "Scenario $scen_type-$type_id for instance $instance does not exist with $agents agents",
            ),
        )
    else
        return scenario[1:agents]
    end
end
