using SatisFactoring
using Test
using SatisFactoring.GenericTensorNetworks
using SatisFactoring:code2hypergraph

@testset "hypergraph" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    problem = GenericTensorNetwork(sat)
    tensor = GenericTensorNetworks.generate_tensors(Tropical(1.0), sat)
    hypergraph = code2hypergraph(problem.code)

    @test hypergraph.v2he == [[1, 2], [1, 4], [1, 2], [1, 2], [2, 3], [3], [4]]
    @test hypergraph.he2v == getixsv(problem.code)
end