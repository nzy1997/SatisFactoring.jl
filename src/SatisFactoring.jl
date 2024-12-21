module SatisFactoring

using OptimalBranchingCore
using OptimalBranchingCore.BitBasis
using GenericTensorNetworks
using GenericTensorNetworks.OMEinsum
using GenericTensorNetworks.ProblemReductions

using GenericTensorNetworks: ∧,∨,¬
# generate random sat problem
using StatsBase
using Random

#hypergraph
export TensorNetworkProblem, sat2tnp, check_satisfiable, neighboring, second_neighboring,random_sat_problem

#branching
export simplify,single_branching,make_branching_table,loss_function,get_val,neighbor_optimal_branching,branching,decide_literal

include("hypergraph.jl")
include("branching.jl")
end
