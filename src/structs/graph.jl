"""
    neighbors_and_weights(g::SimpleWeightedGraph, u::Integer)

Jointly iterate over the neighbors and the corresponding edge weights, more efficiently than in SimpleWeightedGraphs.jl.
"""
function neighbors_and_weights(g::SimpleWeightedGraph, u::Integer)
    w = g.weights
    interval = w.colptr[u]:(w.colptr[u + 1] - 1)
    return zip(  #
        view(w.rowval, interval),
        view(w.nzval, interval),
    )
end

"""
    vectorize_weights(graph::SimpleWeightedGraph)

Return the vector of non-zero weight values in the upper triangle of the adjacency matrix `graph.weights`.

For each edge `(i, j)` with `i <= j`, this allows returning only `w[i, j]` and discarding `w[j, i]`, so that duplicate information is removed.
Thus it is different from `nonzeros(graph.weights)` which keeps the duplicates.

Edges are ordered by increasing `j` and then by increasing `i`.
"""
function vectorize_weights(graph::SimpleWeightedGraph)
    (; weights) = graph
    weights_triu = triu(weights)
    (; nzval) = weights_triu
    return nzval
end

"""
    replace_weights(graph::SimpleWeightedGraph, new_weights_vec::AbstractVector)

Return a new `SimpleWeightedGraph` where the weight values have been replaced by `new_weights_vec`, following the vectorization convention of `vectorize_graph`.

In other words, `replace_weights(graph, vectorize_weights(graph)) == graph`.
"""
function replace_weights(graph::SimpleWeightedGraph, new_weights_vec::AbstractVector)
    (; weights) = graph
    weights_triu = triu(weights)
    (; m, n, colptr, rowval) = weights_triu
    new_weights_triu = SparseMatrixCSC(m, n, colptr, rowval, Vector(new_weights_vec))
    new_weights_triu_strict = triu(new_weights_triu, 1)
    new_weights = new_weights_triu + transpose(new_weights_triu_strict)
    return SimpleWeightedGraph(new_weights)
end
