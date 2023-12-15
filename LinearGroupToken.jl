struct LinearGroupToken{N} <: GroupToken
    vals::SVector{N, ATOMTOKENVALUETYPE}

    function LinearGroupToken(values::Vararg{ATOMTOKENVALUETYPE, N}) where N
        vals = SVector{N, ATOMTOKENVALUETYPE}(maximum([values, reverse(values)]))
        new{N}(vals)
    end
end

LinearGroupToken(values::AbstractVector) = LinearGroupToken(values...)
LinearGroupToken(values::Vararg{AtomToken, N}) where N = LinearGroupToken(value.(values)...)

Base.length(gt::LinearGroupToken) = length(gt.vals)

function Base.show(io::IO, gt::LinearGroupToken{N}) where N
    vals = gt.vals

    print(io, "LinearGroupToken[$N](")
    for i in 1:N
        print(io, atom_token_string(vals[i]))
        if i < N
            print(io, ", ")
        end
    end
    print(io, ")")
end

## 

Base.hash(gt::LinearGroupToken, h::UInt) = Base.hash(gt.vals.data, h)
Base.:(==)(gt1::LinearGroupToken, gt2::LinearGroupToken) = gt1.vals == gt2.vals


a = LinearGroupToken(UInt16.((1, 2, 3))...)
b = LinearGroupToken(UInt16.((3, 2, 1))...)
a == b

c = LinearGroupToken(UInt16.((2, 2, 3))...)
a == c

d = LinearGroupToken(UInt16.((3, 2, 2))...)
c == d

e = LinearGroupToken(UInt16.((100, 200, 300, 100))...)
f = LinearGroupToken(UInt16.((100, 300, 200, 100))...)
@btime e == f
typeof(hash(e))

@btime Base.hash(e) 
Base.hash(f)

"Find all `LinearGroupToken`s that exist in an AtomTokenGraph of size `n`."
function search_linear_group_tokens(atg::AtomTokenGraph, n::Integer)
    found_tokens = Set{LinearGroupToken{n}}()
    function dfs(node, visited, token)
        if length(token) == n
            linear_token = LinearGroupToken(token)
            push!(found_tokens, linear_token)
            
            return
        end
        
        for neighbor in neighbors(atg.graph, node)
            if !(neighbor in visited)
                new_visited = copy(visited)
                push!(new_visited, neighbor)
                
                new_token = copy(token)
                push!(new_token, value(atg.nodemap[neighbor]))
                
                dfs(neighbor, new_visited, new_token)
            end
        end
    end
    
    for node in 1:length(atg)  
        dfs(node, Set([node]), [value(atg.nodemap[node])])
    end
    
    return found_tokens
end

function map_token_recursive(atg::AtomTokenGraph, token::LinearGroupToken, depth::Int, current_node::Int, match_tracker::MVector{N, Int}, visited::BitSet, searchable_nodes::BitSet, matches::Vector{SVector{N, Int}}, max_matches::Number) where N
    if depth > length(match_tracker)
        push!(matches, SVector{N, Int}(match_tracker))
        if length(matches) >= max_matches
            return true  # signal to stop as we've found enough matches
        else
            return false  # continue searching
        end
    end
    
    for neighbor in neighbors(atg.graph, current_node)
        if neighbor in visited || !(neighbor in searchable_nodes)
            continue
        end
        if value(atg.nodemap[neighbor]) == token.vals[depth]
            push!(visited, neighbor)
            match_tracker[depth] = neighbor 
            stop_search = map_token_recursive(atg, token, depth + 1, neighbor, match_tracker, visited, searchable_nodes, matches, max_matches)
            delete!(visited, neighbor)
            
            if stop_search
                return true  # propagate signal to stop the search
            end
        end
    end
    
    return false # continue the search
end

"Find up to `max_matches` sets of indices that match a LinearGroupToken to atoms in an AtomTokenGraph, only searching in `searchable_nodes` and optionally searching indices randomly if `randomsearch` is true."
function map_token(atg::AtomTokenGraph, token::LinearGroupToken{N}, max_matches::Number = 1; searchable_nodes::BitSet=BitSet(1:length(atg)), randomsearch=false) where N
    matches = Vector{SVector{N, Int}}()
    match_tracker = MVector{length(token), Int}(undef)
    for node in (randomsearch ? RandBitSetIterator(searchable_nodes) : searchable_nodes)
        if value(atg.nodemap[node]) == token.vals[1] && node in searchable_nodes
            visited = BitSet([node])
            match_tracker[1] = node
            stop_search = map_token_recursive(atg, token, 2, node, match_tracker, visited, searchable_nodes, matches, max_matches)
            
            if stop_search
                break
            end
        end
    end
    
    return matches 
end

function completely_map_atg(atg::AtomTokenGraph, tokens::AbstractSet{LinearGroupToken{N}}, backup_tokens::AbstractSet{LinearGroupToken{1}}) where N
    searchable_nodes = BitSet(1:length(atg))
    mapped_indices = Vector()
    mapped_tokens = Vector{LinearGroupToken}()

    function token_map_iteration(token)
        mapping = map_token(atg, token, 1; searchable_nodes, randomsearch=true)
        if !isempty(mapping) 
            push!(mapped_indices, mapping[1])
            push!(mapped_tokens, token)
            for val in mapping[1]
                delete!(searchable_nodes, val)
            end 
            return true # found a match
        end
        return false # found nothing
    end

    for token in tokens
        while token_map_iteration(token) end # add tokens of this kind until you cannot anymore. 
        if isempty(searchable_nodes)
            return mapped_indices, mapped_tokens
        end
    end
    for token in backup_tokens
        while token_map_iteration(token) end # add tokens of this kind until you cannot anymore. 
        if isempty(searchable_nodes)
            return mapped_indices, mapped_tokens
        end
    end

    return mapped_indices, mapped_tokens

end


function get_mapping_cache(atg::AtomTokenGraph, tokens::AbstractSet{LinearGroupToken{N}}) where N
    mapping_cache = Dict{LinearGroupToken{N}, Vector{SVector{N}}}()
    for token in tokens
        mappings = map_token(atg, token, Inf; randomsearch=false)
        if !isempty(mappings)
            mapping_cache[token] = mappings
        end
    end
    return mapping_cache
end