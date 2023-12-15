const ATOMTOKENVALUETYPE = UInt16

struct AtomToken
    atomic_number::UInt8
    aromatic::Bool
    hybridization::UInt8  # 1-> sp3, 2 -> sp2, 3 -> sp, 4 -> everything else
end

function Base.show(io::IO, a::AtomToken)
    symbol = atomsymbol(Int64(a.atomic_number))
    print(io, "$(hybridization_str(a.hybridization))$(symbol)" * (a.aromatic ? " (aromatic)" : ""))
end

function atom_token_string(value::ATOMTOKENVALUETYPE)::String
    atomic_number = UInt8(value ÷ 100)
    aromatic = (div(value % 100, 10) == 1)
    hybridization = UInt8(value % 10)
    symbol = atomsymbol(Int64(atomic_number)) 
    return "$(hybridization_str(hybridization))$(symbol)" * (aromatic ? " (aromatic)" : "")
end

function value(a::AtomToken)::ATOMTOKENVALUETYPE
    return ATOMTOKENVALUETYPE(a.atomic_number) * 100 + (a.aromatic ? 10 : 0) + a.hybridization
end

Base.hash(a::AtomToken) = Base.hash(value(a))

function AtomToken(mol::SMILESMolGraph, idx::Integer)
    aromaticity = is_aromatic(mol)[idx]
    atomic_number = UInt8(atomnumber(atomsymbol(mol)[idx]))
    hybrid = UInt8(hybridization_symbol_to_int(hybridization(mol)[idx]))
    return AtomToken(atomic_number, aromaticity, hybrid)
end

TOKEN_DICT_TYPE = Dict{AtomToken, Int64}

new_token_dict() = TOKEN_DICT_TYPE()

struct AtomTokenIterator
    g::SMILESMolGraph
end

Base.length(itr::AtomTokenIterator) = MolecularGraph.nv(itr.g)

function Base.iterate(itr::AtomTokenIterator, state=1)
    if state > MolecularGraph.nv(itr.g)
        return nothing  
    end

    token = AtomToken(itr.g, state)

    return token, state + 1
end

function discover_tokens!(found_tokens::TOKEN_DICT_TYPE, g::SMILESMolGraph)
    for token in AtomTokenIterator(g)
        if !haskey(found_tokens, token)
            found_tokens[token] = 1
        else
            found_tokens[token] += 1
        end
    end
end




