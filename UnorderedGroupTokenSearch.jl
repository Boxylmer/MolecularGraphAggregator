function find_group_tokens(atg::AtomTokenGraph, gt::UnorderedGroupToken)
    found_instances = Vector{Vector{Int}}()
    excluded_nodes = Set{Int}()
    
    for node in vertices(atg.graph)
        # Check if this node's AtomToken is in the UnorderedGroupToken
        if atg.nodemap[node] in gt.sortedvals
            instance = exhaustive_group_token_search(atg, node, gt, excluded_nodes)
            if !isempty(instance)
                push!(found_instances, instance)
            end
            push!(node, excluded_nodes)
        end
    end
    return found_instances
end

function exhaustive_group_token_search(atg::AtomTokenGraph, node::Int, gt::UnorderedGroupToken, excluded_nodes::Set{Int})


end



atg = AtomTokenGraph(parse_smiles("CCCCO"))
plot(atg.graph, curves=false)
[println(find_group_tokens(atg, level_2_groups[i])) for i in eachindex(level_2_groups)]




