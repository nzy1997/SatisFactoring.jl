using Test,SatisFactoring
using SatisFactoring.GenericTensorNetworks
using SatisFactoring: second_neighbor_optimal_branching
import SatisFactoring.OptimalBranchingCore
using SatisFactoring.OptimalBranchingCore: BranchingTable, candidate_clauses
using SatisFactoring: BranchingSituation
using SatisFactoring.GenericTensorNetworks.ProblemReductions
using SatisFactoring.BitBasis
using SatisFactoring.Random

@testset "simplify1" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c), ∨(¬a))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    tnp2 = simplify(tnp)

    @test tnp2.vals == Bool[0, 0, 0, 0, 0,0,0]
    @test tnp2.he2v == [[2, 3, 4], [5, 6], [2, 7]]
end

@testset "simplify2" begin
    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    tnp2 = simplify(tnp)

    @test tnp2.vals == Bool[1, 0, 0, 1, 0]
    @test tnp2.he2v == [[2, 5]]
end

@testset "simplify3" begin
    circuit = @circuit begin
        c = x ∧ y
    end
    sat = CircuitSAT(circuit)
    tnp = sat2tnp(sat)
    tensors = tnp.tensors
    he2v = tnp.he2v

    push!(tensors, [Tropical(1.0), Tropical(0.0)])
    push!(he2v, [1])

    tnp2 = TensorNetworkProblem(tensors, he2v, tnp.vals, tnp.symbols)
    tnp3 = simplify(tnp2)
    @test tnp3.vals == Bool[1, 1, 1]
    @test tnp3.he2v == []
end

@testset "single_branching" begin
    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    ans,tnp = single_branching(cnf)
    @test ans == true
    @test check_satisfiable(tnp,cnf)

    cnf = ∧(∨(a), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c), ∨(¬a))
    ans,tnp = single_branching(cnf)
    @test ans == false
    @test !check_satisfiable(tnp,cnf)
end

@testset "make_branching_table" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    subtnp = neighboring(tnp,1)
    tbl = make_branching_table(subtnp,tnp)
    @test tbl == BranchingTable(5, [[[0, 0, 0, 0, 0]], [[0, 1, 0, 0, 0]], [[0, 0, 0, 0, 1]], [[0, 1, 0, 0, 1]]])

    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)

    subtnp = second_neighboring(tnp,1)
    tbl = make_branching_table(subtnp,tnp) 
    @test tbl== BranchingTable(3,[[[1,0,1]]])
end

@testset "loss_function" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    subtnp = neighboring(tnp,1)
    cl = OptimalBranchingCore.Clause(LongLongUInt{1}(0x000000000000000f,),LongLongUInt{1}(0x0000000000000000,))
    @test loss_function(tnp, cl, subtnp.vs) == 3
    
    cl = OptimalBranchingCore.Clause(LongLongUInt{1}(0x000000000000001d,),LongLongUInt{1}(0x0000000000000000,))
    @test loss_function(tnp, cl,subtnp.vs) == 3

    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    subtnp = neighboring(tnp,2)
    tbl = make_branching_table(subtnp,tnp)
    cl = collect(OptimalBranchingCore.candidate_clauses(tbl))
    @test loss_function(tnp,cl[1],subtnp.vs) == 6
end

@testset "second_neighbor_optimal_branching" begin
    @bools a b c d e f g
    cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))
    sat = Satisfiability(cnf)
    tnp = sat2tnp(sat)
    subtnp = neighboring(tnp,1)
    tbl = make_branching_table(subtnp,tnp)
    @test second_neighbor_optimal_branching(tnp)[1] == BranchingSituation(collect(1:7),[1,1,1,1,2,1,1])
    @test neighbor_optimal_branching(tnp) == [BranchingSituation([1,3,4],[1,1,1])]
end

@testset "single_branching" begin
    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    tnp = sat2tnp(Satisfiability(cnf))
    ans,tnp = branching(tnp,second_neighbor_optimal_branching)
    @test ans == true
    @test check_satisfiable(tnp,cnf)

    cnf = ∧(∨(a), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c), ∨(¬a))
    tnp = sat2tnp(Satisfiability(cnf))
    ans,tnp = branching(tnp,second_neighbor_optimal_branching)
    @test ans == false
    @test !check_satisfiable(tnp,cnf)
end

@testset "decide_literal" begin
    @bools a b c d e
    cnf = ∧(∨(b), ∨(a,¬c), ∨(d,¬b), ∨(¬c,¬d), ∨(a,e), ∨(a,e,¬c))
    tnp = TensorNetworkProblem(Array{Tropical{Float64}}[[1.0 0.0; 0.0 0.0]], [[2, 5]], Bool[1, 0, 0, 1, 0], [:b, :a, :c, :d, :e])
    tnp2 =decide_literal(tnp,BranchingSituation([2, 5], [2, 1]))
    @test check_satisfiable(tnp2,cnf)

    @bools a 
    cnf = ∧(∨(a), ∨(¬a))
    tnp = sat2tnp(Satisfiability(cnf))
    decide_literal(tnp,1,1)
end

@testset "factoring" begin
    factoring = Factoring(2, 2, 6)
    res = reduceto(CircuitSAT, factoring)
    tnp = sat2tnp(res.circuit)

    ans,tnp = branching(tnp,second_neighbor_optimal_branching)
    @test ans == true
    assignment3 = Dict(zip(res.circuit.symbols, tnp.vals))
    a, b = ProblemReductions.read_solution(factoring, [tnp.vals[res.p]...,tnp.vals[res.q]...])
    @test a * b == 6
end

@testset "circuitsat" begin
    circuit = @circuit begin
        c = x ∧ y
    end
    push!(circuit.exprs, Assignment([:c],BooleanExpr(true)))
    sat = CircuitSAT(circuit)
    tnp = sat2tnp(sat)
    # ??
end

@testset "random_sat_problem" begin
    Random.seed!(1)
    num = 100
    for i in 1:num
        sat = random_sat_problem(5, 10)
        tnp = sat2tnp(sat)
        ans,tnp_outcome = branching(tnp,single_branching)
        ans2, tnp_outcome2 = branching(tnp,second_neighbor_optimal_branching)
        @test ans2 == ans
        if ans
            @test check_satisfiable(tnp_outcome,sat.cnf)
            @test check_satisfiable(tnp_outcome2,sat.cnf)
        else
            check_satisfiable(tnp_outcome,sat.cnf) && (@show i)
            @test !check_satisfiable(tnp_outcome,sat.cnf)
            @test !check_satisfiable(tnp_outcome2,sat.cnf)
        end
    end
end