using SatisFactoring
using Test

@testset "SatisFactoring.jl" begin
    fact3 = Factoring(3, 3, 6)
    res3 = reduceto(CircuitSAT, fact3)
end

using GenericTensorNetworks
using ProblemReductions

@bools a b c d e f g

cnf = ∧(∨(a, b, ¬d, ¬e), ∨(¬a, d, e, ¬f), ∨(f, g), ∨(¬b, c))

cnf2 = ∨(a, b)
GenericTensorNetwork(res3.circuit)

reduceto(ProblemReductions.Satisfiability,res3.circuit)

reduction_result = reduceto(ProblemReductions.SpinGlass{<:SimpleGraph}, res3.circuit)
res = target_problem(reduction_result)
GenericTensorNetwork()