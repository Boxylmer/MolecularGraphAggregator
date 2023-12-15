function hybridization_symbol_to_int(hybridization::Symbol)  # possibly move to utils if needed elsewhere
    return hybridization === :sp3 ? 1 : 
           hybridization === :sp2 ? 2 : 
           hybridization === :sp  ? 3 : 4
end

hybridization_str(hybridization::UInt8) = begin
    return hybridization == 1 ? "sp3 " :
           hybridization == 2 ? "sp2 " :
           hybridization == 3 ? "sp "  :
                                 ""
end




struct RandBitSetIterator
    bs::BitSet
    remaining_indices::Vector{Int}
end

function RandBitSetIterator(bs::BitSet)
    RandBitSetIterator(bs, collect(bs))
end

function Base.iterate(iter::RandBitSetIterator, state=1)
    if isempty(iter.remaining_indices)
        return nothing
    end
    index = rand(1:length(iter.remaining_indices))
    value = iter.remaining_indices[index]
    deleteat!(iter.remaining_indices, index)
    return value, length(iter.remaining_indices)
end

Base.IteratorSize(::Type{RandBitSetIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{RandBitSetIterator}) = Base.HasEltype()
Base.eltype(::Type{RandBitSetIterator}) = Int