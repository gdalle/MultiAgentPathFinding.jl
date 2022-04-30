Base.@kwdef struct CBSNode
    parent::Union{Nothing,CBSNode}
    constraint::Union{Nothing,Tuple{Int,Int,Int}}
    solution::Solution
    cost::Int
    conflict_heuristic::Int
end

function cbs_low_level(node, additional_constraint, mapf::MAPF)
    forbidden_vertices = Reservation()
    a, t, g = additional_constraint
    for v in mapf.conflict_groups[g]
        push!(forbidden_vertices, (t, v))
    end
    while true
        if isnothing(node.constraint)
            break
        else
            b, t, g = node.constraint
            if b == a
                for v in mapf.conflict_groups[g]
                    push!(forbidden_vertices, (t, v))
                end
            end
            node = node.parent
        end
    end
    graph, edge_weights = mapf.graph, mapf.edge_weights
    s, d, t0 = mapf.sources[a], mapf.destinations[a], mapf.starting_times[a]
    dist = mapf.distances_to_destinations[d]
    heuristic(v) = dist[v]
    path = temporal_astar(
        graph,
        s,
        d,
        t0;
        edge_weights=edge_weights,
        heuristic=heuristic,
        forbidden_vertices=forbidden_vertices,
    )
    return path
end

function conflict_based_search(mapf::MAPF; greedy=true)
    root_solution = independent_astar(mapf)
    root_cost = flowtime(root_solution, mapf)
    root_conflict_heuristic = nb_conflicting_pairs(root_solution, mapf)
    root = CBSNode(;
        parent=nothing,
        constraint=nothing,
        solution=root_solution,
        cost=root_cost,
        conflict_heuristic=root_conflict_heuristic,
    )

    if greedy
        open_queue = VectorPriorityQueue{CBSNode,Tuple{Int,Int}}()
        enqueue!(open_queue, root, (root.conflict_heuristic, root.cost))
    else
        open_queue = VectorPriorityQueue{CBSNode,Int}()
        enqueue!(open_queue, root, root.cost)
    end

    prog = ProgressUnknown("Nodes explored in the conflict tree:")
    while !isempty(open_queue)
        ProgressMeter.next!(prog)

        node = dequeue!(open_queue)
        has_empty_paths(node.solution) && continue
        conflict = find_conflict(node.solution, mapf)

        if isnothing(conflict)
            return node.solution
        else
            (; a, b, t, g) = conflict

            constraint_a = (a, t, g)
            solution_a = copy(node.solution)
            solution_a[a] = cbs_low_level(node, constraint_a, mapf)
            cost_a = flowtime(solution_a, mapf)
            conflict_heuristic_a = nb_conflicting_pairs(solution_a, mapf)
            node_a = CBSNode(;
                parent=node,
                constraint=(a, t, g),
                solution=solution_a,
                cost=cost_a,
                conflict_heuristic=conflict_heuristic_a,
            )

            constraint_b = (b, t, g)
            solution_b = copy(node.solution)
            solution_b[b] = cbs_low_level(node, constraint_b, mapf)
            cost_b = flowtime(solution_b, mapf)
            conflict_heuristic_b = nb_conflicting_pairs(solution_b, mapf)
            node_b = CBSNode(;
                parent=node,
                constraint=(b, t, g),
                solution=solution_b,
                cost=cost_b,
                conflict_heuristic=conflict_heuristic_b,
            )

            if greedy
                enqueue!(open_queue, node_a, (node_a.conflict_heuristic, node_a.cost))
                enqueue!(open_queue, node_b, (node_b.conflict_heuristic, node_b.cost))
            else
                enqueue!(open_queue, node_a, node_a.cost)
                enqueue!(open_queue, node_b, node_b.cost)
            end
        end
    end
    return nothing
end
