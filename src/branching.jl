function simplify(tnp::TensorNetworkProblem)
    he2v = copy(tnp.he2v)
	tensors = copy(tnp.tensors)
	vals = copy(tnp.vals)
    he2v, tensors = remove_zeros!(he2v, tensors)
    unitedge = findfirst(x -> count(==(Tropical(0.0)),x) == 1 ,tensors)
	while !isnothing(unitedge)
		vs = he2v[unitedge]
        v_val = findfirst(==(Tropical(0.0)), tensors[unitedge])
        if v_val isa CartesianIndex
            v_val = collect(v_val.I)
        else
            vs = vs[1]
        end
		he2v, tensors, vals = decide_literal!(he2v, tensors, vals, vs, v_val)
        he2v, tensors = remove_zeros!(he2v, tensors)
        unitedge = findfirst(x -> count(==(Tropical(0.0)),x) == 1 ,tensors)
	end
	return TensorNetworkProblem(tensors, he2v, vals, tnp.symbols)
end

function remove_zeros!(he2v, tensors)
    allzeros = [all(==(Tropical(0.0)), t) for t in tensors]
    he2v = he2v[.!allzeros]
    tensors = tensors[.!allzeros]
    return he2v, tensors
end

function decide_literal!(he2v, tensors, vals, v, v_val::Int)
	vals[v] = (v_val == 2)
	vedges = findall(x -> v in x, he2v)
	for edge_num in vedges
		v_num = findfirst(==(v), he2v[edge_num])
		if length(he2v[edge_num]) == 1
			tensors[edge_num] = [tensors[edge_num][fill(:, v_num - 1)..., v_val, fill(:, length(he2v[edge_num]) - v_num)...]]
		else
			tensors[edge_num] = tensors[edge_num][fill(:, v_num - 1)..., v_val, fill(:, length(he2v[edge_num]) - v_num)...]
		end
		he2v[edge_num] = setdiff(he2v[edge_num], [v])
	end
	return he2v, tensors, vals
end

function decide_literal(tnp::TensorNetworkProblem, v::Int, v_val::Int)
	return decide_literal(tnp, [v], [v_val])
end

function decide_literal(tnp::TensorNetworkProblem, dls::Vector{Int}, new_vals::Vector{Bool})
	return decide_literal(tnp, dls, [v ? 2 : 1 for v in new_vals])
end

struct BranchingSituation
	dls::Vector{Int}
	vals::Vector{Int}
end

Base.:(==)(bs1::BranchingSituation, bs2::BranchingSituation) = (bs1.dls == bs2.dls) && (bs1.vals == bs2.vals)

function decide_literal(tnp::TensorNetworkProblem, bs::BranchingSituation)
	return decide_literal(tnp, bs.dls, bs.vals)
end

function decide_literal!(he2v, tensors, vals, dls::Vector{Int}, new_vals::Vector{Int})
    for i in 1:length(dls)
		v = dls[i]
		v_val = new_vals[i]
		he2v, tensors, vals = decide_literal!(he2v, tensors, vals, v, v_val)
	end
    return he2v, tensors, vals
end

function decide_literal(tnp::TensorNetworkProblem, dls::Vector{Int}, new_vals::Vector{Int})
	he2v = copy(tnp.he2v)
	tensors = copy(tnp.tensors)
	vals = copy(tnp.vals)
    he2v, tensors, vals = decide_literal!(he2v, tensors, vals, dls, new_vals)
	return TensorNetworkProblem(tensors, he2v, vals, tnp.symbols)
end

function branching(tnp::TensorNetworkProblem, branching_strategy)
	tnp = simplify(tnp)
    if tnp.he2v == []
		return true, tnp
	end
	if any([all(==(Tropical(1.0)), t) for t in tnp.tensors])
		return false, tnp
	end

	bss = branching_strategy(tnp)
	for bs in bss
		res, tnp = branching(decide_literal(tnp, bs), branching_strategy)
		if res
			return true, tnp
		end
	end
	return false, tnp
end

function single_branching(cnf::CNF{Symbol})
	sat = Satisfiability(cnf)
	tnp = sat2tnp(sat)
	res, tnp = branching(tnp, single_branching)
	return res, tnp
end

function single_branching(tnp::TensorNetworkProblem)
	v = tnp.he2v[1][1]
	return [BranchingSituation([v], [1]), BranchingSituation([v], [2])]
end

function second_neighbor_optimal_branching(tnp::TensorNetworkProblem)
	v = tnp.he2v[1][1]
	subtnp = second_neighboring(tnp, v)
	return subtnp_optimal_branching(tnp, subtnp)
end

function neighbor_optimal_branching(tnp::TensorNetworkProblem)
	v = tnp.he2v[1][1]
	subtnp = neighboring(tnp, v)
	return subtnp_optimal_branching(tnp, subtnp)
end

function subtnp_optimal_branching(tnp::TensorNetworkProblem, subtnp::SubTNP)
	tbl = make_branching_table(subtnp, tnp)
	candidates = collect(OptimalBranchingCore.candidate_clauses(tbl))
	Δρ = [loss_function(tnp, cl, subtnp.vs) for cl in candidates]
	res_ip = OptimalBranchingCore.minimize_γ(tbl, candidates, Δρ, IPSolver())
	return [BranchingSituation(get_val(cl, subtnp.vs)...) for cl in res_ip.optimal_rule.clauses]
end

function make_branching_table(subtnp::SubTNP, tnp::TensorNetworkProblem)
	eincode = DynamicEinCode{Int}(tnp.he2v[subtnp.edges], subtnp.vs)
	optcode = optimize_code(eincode, uniformsize(eincode, 2), TreeSA())
	sub_tensors = optcode(tnp.tensors[subtnp.edges]...)
	out_vs_num = length(subtnp.outside_vs_ind)
	vs_num = length(subtnp.vs)
	ind_pos = [i ∈ subtnp.outside_vs_ind ? findfirst(==(i), subtnp.outside_vs_ind) : findfirst(==(i), setdiff(1:vs_num, subtnp.outside_vs_ind)) for i in 1:vs_num]
	possible_configurations = Vector{Vector{Bool}}[]
	for i in 0:(2^out_vs_num-1)
		answer = [i & (1 << j) != 0 for j in 0:out_vs_num-1]
		out_index = [i ? 2 : 1 for i in answer]
		vec = [i ∈ subtnp.outside_vs_ind ? out_index[ind_pos[i]] : (:) for i in 1:vs_num]
		new_tensors = sub_tensors[vec...]
		in_index = findfirst(==(Tropical(0.0)), new_tensors)
		if isnothing(in_index)
			continue
		end
		push!(possible_configurations, [[i ∈ subtnp.outside_vs_ind ? out_index[ind_pos[i]] : in_index[ind_pos[i]] for i in 1:vs_num] .== fill(2, vs_num)])
	end
	return BranchingTable(vs_num, possible_configurations)
end

function loss_function(tnp::TensorNetworkProblem, cl::Clause, sub_pos::Vector{Int})
	pos, val = get_val(cl, sub_pos)
	edge_num = length(tnp.he2v)
	tnpnew = decide_literal(tnp, pos, val)
	tnpnew2 = simplify(tnpnew)
	return edge_num - length(tnpnew2.he2v)
end

function get_val(cl::Clause, sub_pos::Vector{Int})
	pos = [i + 1 for i in 0:63 if Int(cl.mask.content[1] >> i) % 2 == 1]
	val = [(Int(cl.val.content[1] >> (i-1)) % 2 == 1) ? 2 : 1 for i in pos]
	return sub_pos[pos], val
end
