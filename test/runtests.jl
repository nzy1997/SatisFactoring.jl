using SatisFactoring
using Test

@testset "hypergraph.jl" begin
    include("hypergraph.jl")
end

@testset "branching.jl" begin
    include("branching.jl")
end