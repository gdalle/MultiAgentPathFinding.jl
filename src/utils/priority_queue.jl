struct VectorPriorityQueue{K,V}
    keys::Vector{K}
    values::Vector{V}
end

VectorPriorityQueue{K,V}() where {K,V} = VectorPriorityQueue{K,V}(K[], V[])

function enqueue!(pq::VectorPriorityQueue{K,V}, k::K, v::V) where {K,V}
    left = searchsortedfirst(pq.values, v)
    insert!(pq.keys, left, k)
    insert!(pq.values, left, v)
end

function Base.deleteat!(pq::VectorPriorityQueue, args...)
    deleteat!(pq.keys, args...)
    deleteat!(pq.values, args...)
end

function dequeue!(pq::VectorPriorityQueue)
    k = popfirst!(pq.keys)
    popfirst!(pq.values)
    return k
end

Base.length(pq::VectorPriorityQueue) = length(pq.keys)
Base.keys(pq::VectorPriorityQueue) = pq.keys
Base.values(pq::VectorPriorityQueue) = pq.values
Base.isempty(pq::VectorPriorityQueue) = isempty(pq.keys)
Base.pairs(pq::VectorPriorityQueue) = (k => v for (k, v) in zip(pq.keys, pq.values))
