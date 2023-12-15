struct UnorderedGroupToken{N}
    sortedvals::MVector{N, ATOMTOKENVALUETYPE}
end

function UnorderedGroupToken(values::Vararg{ATOMTOKENVALUETYPE, N}) where N
    sorted_vals = sort(MVector{N, ATOMTOKENVALUETYPE}(values))
    return UnorderedGroupToken{N}(sorted_vals::MVector{N, ATOMTOKENVALUETYPE})
end

UnorderedGroupToken(values::Vararg{AtomToken, N}) where N = UnorderedGroupToken(value.(values)...)

Base.length(gt::UnorderedGroupToken) = length(gt.sortedvals)

function combinations_with_replacement(values::AbstractVector, N::Int)
    if N == 1
        return [[v] for v in values]
    else
        combs = []
        for (i, v) in enumerate(values)
            for sub_comb in combinations_with_replacement(values[i:end], N-1)
                push!(combs, [v; sub_comb])
            end
        end
        return combs
    end
end

function generate_group_tokens(atomtokens::Set{AtomToken}, N::Int)
    values = [value(t) for t in atomtokens]
    combs = combinations_with_replacement(values, N)
    return [UnorderedGroupToken(c...) for c in combs]
end

generate_group_tokens(atomtokens::Dict{AtomToken, <:Any}, N::Int) = generate_group_tokens(Set(keys(atomtokens)), N)



