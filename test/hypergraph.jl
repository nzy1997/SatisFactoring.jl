using SatisFactoring
using Test
using SatisFactoring.GenericTensorNetworks
using Random

@testset "TensorNetworkProblem" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    problem = GenericTensorNetwork(sat)
    tensor = GenericTensorNetworks.generate_tensors(Tropical(1.0), sat)

    tnp = sat2tnp(sat)
    @test tnp.he2v == getixsv(problem.code)
end

@testset "check_satisfiable" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    @test !check_satisfiable(tnp,cnf)
    tnp2 = TensorNetworkProblem(tnp.tensors, tnp.he2v,[true,false,true,false,true,true,true] , tnp.symbols)
    @test check_satisfiable(tnp2,cnf)
end

@testset "neighboring" begin
    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)

    subtnp = neighboring(tnp,1)
    @test subtnp.vs == [1, 4]
    @test subtnp.edges == [1,3]
    @test subtnp.outside_vs_ind == [2]

    subtnp = neighboring(tnp,2)
    @test subtnp.vs == [2, 3, 5]
    @test subtnp.edges == [2,5,6]
    @test subtnp.outside_vs_ind == [2]
end

@testset "second_neighboring" begin
    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)

    subtnp = second_neighboring(tnp,1)
    @test subtnp.vs == [1, 3, 4]
    @test subtnp.edges == [1, 3, 4]
    @test subtnp.outside_vs_ind == [2]

    subtnp = second_neighboring(tnp,2)
    @test subtnp.vs == [2, 3, 4, 5]
    @test subtnp.edges == [2, 4, 5, 6]
    @test subtnp.outside_vs_ind == [3]

    subtnp = second_neighboring(tnp,3)
    @test subtnp.vs == [1, 2, 3, 4, 5]
    @test subtnp.edges == [2, 3, 4, 5, 6]
    @test subtnp.outside_vs_ind == [1] # unit clause!!
end

@testset "second_neighboring2" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)

    subtnp = second_neighboring(tnp,1)
    @test subtnp.vs == collect(1:7)
    @test subtnp.edges == collect(1:4)
    @test subtnp.outside_vs_ind == []

    subtnp = second_neighboring(tnp,7)
    @test subtnp.vs == [1, 2, 3, 4, 7]
    @test subtnp.edges == [1,4]
    @test subtnp.outside_vs_ind == [1,3,4]
end

@testset "random_sat_problem" begin
    Random.seed!(1234)
    sat = random_sat_problem(5, 10)

    @test length(sat.cnf) == 10
    @test length(sat.symbols) == 5
end