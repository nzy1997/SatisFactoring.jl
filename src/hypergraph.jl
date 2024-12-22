struct TensorNetworkProblem
    tensors::Vector{Array{Tropical{Float64}}}
    he2v::Vector{Vector{Int}}
    vals::Vector{Bool}
    symbols::Vector{Symbol}
end

v2he(he2v::Vector{Vector{Int}}) = [findall(x->i in x, he2v) for i in 1:maximum(maximum,he2v)]
v2he(tnp::TensorNetworkProblem) = v2he(tnp.he2v)

function sat2tnp(sat::ConstraintSatisfactionProblem)
    problem = GenericTensorNetwork(sat)
    he2v = getixsv(problem.code)
    tensors = GenericTensorNetworks.generate_tensors(Tropical(1.0), problem)
    return TensorNetworkProblem(tensors, he2v, fill(false, maximum(maximum,he2v)), problem.problem.symbols)
end

function check_satisfiable(tnp::TensorNetworkProblem,cnf::CNF)
    return satisfiable(cnf, Dict(zip(tnp.symbols,tnp.vals)))
end

struct SubTNP
    vs::Vector{Int}
    edges::Vector{Int}
    outside_vs_ind::Vector{Int}
end
function second_neighboring(tnp::TensorNetworkProblem, v::Int)
    vs = neighboring(tnp, v).vs
    return neighboring(tnp, vs)
end

function neighboring(tnp::TensorNetworkProblem, vs::Vector{Int})
    edges = sort([i for i in 1:length(tnp.he2v) if !isempty(tnp.he2v[i] ∩ vs)])
    vs = sort(reduce(∪, tnp.he2v[edges]))
    return SubTNP(vs, edges,[ind for ind in 1:length(vs) if any([vs[ind] ∈ v for v in tnp.he2v[setdiff(1:length(tnp.he2v),edges)]])])
end

function neighboring(tnp::TensorNetworkProblem, v::Int)
    return neighboring(tnp, [v])
end

function random_sat_problem(literal_num::Int, clause_num::Int)
    symbols = [Symbol("x$i") for i in 1:literal_num]
    clauses = CNFClause{Symbol}[]
    for _ in 1:clause_num
        true_literals = sample(1:literal_num, rand(0:literal_num-1), replace=false)
        false_literals = sample(setdiff(1:literal_num,true_literals), rand(0:literal_num-length(true_literals)), replace=false)
        clause = CNFClause{Symbol}([[BoolVar{Symbol}(symbols[i],false) for i in true_literals]..., [BoolVar{Symbol}(symbols[i],true) for i in false_literals]...])
        if length(clause) == 0
            continue
        end
        push!(clauses, clause)
    end
    return Satisfiability(CNF(clauses))
end