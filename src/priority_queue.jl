struct MyPriorityQueue{K,V}
    keys::Vector{K}
    values::Vector{V}
end

MyPriorityQueue{K,V}() where {K,V} = MyPriorityQueue{K,V}(K[], V[])

function enqueue!(pq::MyPriorityQueue{K,V}, k::K, v::V) where {K,V}
    left = searchsortedfirst(pq.values, v)
    insert!(pq.keys, left, k)
    insert!(pq.values, left, v)
end

function Base.deleteat!(pq::MyPriorityQueue, i::Integer)
    deleteat!(pq.keys, i)
    deleteat!(pq.values, i)
end

function dequeue!(pq::MyPriorityQueue)
    k = popfirst!(pq.keys)
    popfirst!(pq.values)
    return k
end

Base.length(pq::MyPriorityQueue) = length(pq.keys)
Base.keys(pq::MyPriorityQueue) = pq.keys
Base.values(pq::MyPriorityQueue) = pq.values
Base.isempty(pq::MyPriorityQueue) = isempty(pq.keys)
Base.pairs(pq::MyPriorityQueue) = (k => v for (k, v) in zip(pq.keys, pq.values))
