struct Hypergraph
    v2he::Vector{Vector{Int}}
    he2v::Vector{Vector{Int}}
end
function Hypergraph(he2v::Vector{Vector{Int}})
    v2he = [findall(x->i in x, he2v) for i in 1:maximum(maximum,he2v)]
    return Hypergraph(v2he, he2v)
end

function code2hypergraph(code::AbstractEinsum)
    he2v = getixsv(code)
    return Hypergraph(he2v)
end