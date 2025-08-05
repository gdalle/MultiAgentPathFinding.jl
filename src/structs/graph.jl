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
