using Graphs
using SimpleWeightedGraphs
using SparseArrays0
using MultiAgentPathFinding: neighbors_and_weights, replace_weights, vectorize_weights
using Test

g = SimpleWeightedGraph([
    0 1 2 4
    1 0 3 0
    2 3 0 0
    4 0 0 0
])

h = SimpleWeightedGraph([
    10 1 2 4
    1 20 3 0
    2 3 0 0
    4 0 0 0
])

@testset "Neighbors" begin
    @test collect(neighbors_and_weights(g, 1)) == [(2, 1), (3, 2), (4, 4)]
    @test collect(neighbors_and_weights(g, 2)) == [(1, 1), (3, 3)]
    @test collect(neighbors_and_weights(g, 3)) == [(1, 2), (2, 3)]
    @test collect(neighbors_and_weights(g, 4)) == [(1, 4)]
end

@testset "Vectorize" begin
    @test vectorize_weights(g) == [1, 2, 3, 4]
    @test vectorize_weights(g) ==
        [get_weight(g, src(e), dst(e)) for e in edges(g) if src(e) <= dst(e)]
    @test vectorize_weights(h) == [10, 1, 20, 2, 3, 4]
    @test vectorize_weights(h) ==
        [get_weight(h, src(e), dst(e)) for e in edges(h) if src(e) <= dst(e)]
end

@testset "Replace" begin
    g2 = replace_weights(g, [4, 3, 2, 1])
    @test g2.weights == [
        0 4 3 1
        4 0 2 0
        3 2 0 0
        1 0 0 0
    ]

    h2 = replace_weights(h, [30, 4, 40, 3, 2, 1])
    @test h2.weights == [
        30 4 3 1
        4 40 2 0
        3 2 0 0
        1 0 0 0
    ]
end
