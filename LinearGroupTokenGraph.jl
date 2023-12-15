struct LinearGroupTokenGraph
    graph::SimpleGraph
    nodes::Vector{LinearGroupToken}
end
function LinearGroupTokenGraph(atg::AtomTokenGraph, token_mapping::Dict{SVector, LinearGroupToken})
    # Initialize the graph with the number of vertices equal to the number of unique groups
    lg_graph = SimpleGraph(length(token_mapping))
    tokens = collect(values(token_mapping))
    # Keep track of which token each atom-node belongs to
    atom_to_group = Dict()
    group_to_index = Dict()
    
    for (i, (group, _)) in enumerate(token_mapping)
        group_to_index[group] = i
        for atom in group
            atom_to_group[atom] = group
        end
    end

    # Create edges between groups if their corresponding atom-nodes are neighbors in the original graph
    for edge in edges(atg.graph)
        node_1, node_2 = src(edge), dst(edge)
        group_1, group_2 = atom_to_group[node_1], atom_to_group[node_2]

        if group_1 !== group_2  # Don't add self-loops
            src_index, dst_index = group_to_index[group_1], group_to_index[group_2]
            add_edge!(lg_graph, src_index, dst_index)
        end
    end

    return LinearGroupTokenGraph(lg_graph, tokens)
end



struct LinearGroupTokenGraphGenerator{N}
    atg::AtomTokenGraph
    token_mappings::Dict{LinearGroupToken{N}, Vector{SVector{N}}}
    backup_mappings::Dict{LinearGroupToken{1}, Vector{SVector{1}}}
   
    node_to_groups::Dict{Int64, Vector{SVector{N, Int64}}}
    group_to_token::Dict{SVector{N, Int64}, LinearGroupToken{N}}
    

    node_to_backup_token::Dict{Int64, LinearGroupToken{1}}
end

function LinearGroupTokenGraphGenerator(atg::AtomTokenGraph, tokens::AbstractSet{LinearGroupToken{N}}, backup_tokens::AbstractSet{LinearGroupToken{1}}) where N
    token_mappings = get_mapping_cache(atg, tokens)
    backup_mappings = get_mapping_cache(atg, backup_tokens)

    node_to_groups = Dict{Int64, Vector{SVector{N, Int64}}}()
    for node in 1:length(atg)
        node_to_groups[node] = Vector{SVector{N, Int64}}()
    end
    group_to_token = Dict{SVector{N, Int64}, LinearGroupToken{N}}()

    for token in keys(token_mappings)
        for node_indices in token_mappings[token]
            for node in node_indices
                push!(node_to_groups[node], node_indices)
            end
            group_to_token[node_indices] = token
        end
    end

    node_to_backup_tokens = Dict{Int64, LinearGroupToken{1}}()
    for token in keys(backup_mappings)
        nodes = backup_mappings[token]
        for node in nodes
            node_to_backup_tokens[node[1]] = token
        end
    end

    return LinearGroupTokenGraphGenerator(atg, token_mappings, backup_mappings, node_to_groups, group_to_token, node_to_backup_tokens)
end

function randomgraph(lgtgg::LinearGroupTokenGraphGenerator)
    assigned_nodes = BitSet()
    token_mapping = Dict{SVector, LinearGroupToken}()
    
    # Step 2: Shuffle the nodes for random order
    shuffled_nodes = shuffle(collect(keys(lgtgg.node_to_groups)))
    
    for node in shuffled_nodes
        if !(node in assigned_nodes)
            possible_groups = copy(lgtgg.node_to_groups[node])
            
            shuffle!(possible_groups)
            
            for group in possible_groups
                if all(map(n -> !(n in assigned_nodes), group))
                    token = lgtgg.group_to_token[group]
                    token_mapping[SVector(group)] = token
                    union!(assigned_nodes, group)
                    break
                end
            end
        end
    end
    
    # Step 4: Use backup tokens for unassigned nodes
    unassigned_nodes = setdiff(1:length(lgtgg.atg.nodemap), assigned_nodes)
    for node in unassigned_nodes
        backup_token = lgtgg.node_to_backup_token[node]
        token_mapping[SVector{1, Int64}([node])] = backup_token 
        push!(assigned_nodes, node)
    end
    
    # return token_mapping

    return LinearGroupTokenGraph(lgtgg.atg, token_mapping)
end