using Graphs
using BenchmarkTools
using DataStructures

function find_all_subgraphs(g::SimpleGraph, start_node::Int, node_blacklist::Set{Int}, labels::Vector{String}, subgraph_type::Dict{String, Int})
    all_subgraphs = Set{Vector{Int}}()
    seen_subgraphs = Set{BitSet}()
    scratch = BitSet()
    
    # Initialize type counter based on the type of the start node
    remaining_needed = copy(subgraph_type)
    
    # Handle start node
    start_label = labels[start_node]
    if !haskey(remaining_needed, start_label)
        return collect(all_subgraphs)
    end
    
    remaining_needed[start_label] -= 1
    
    # Initialize
    start_visited = BitSet([start_node])
    push!(seen_subgraphs, start_visited)
    queue = [([start_node], start_visited, remaining_needed)]
    
    while !isempty(queue)
        current_subgraph, visited, remaining = popfirst!(queue)
        
        # If we've found all types, add the current subgraph to all_subgraphs
        if all(v -> v == 0, values(remaining))
            push!(all_subgraphs, current_subgraph)
            continue
        end
        
        for last_node in current_subgraph
            for neighbor in neighbors(g, last_node)
                if !(neighbor in visited) && !(neighbor in node_blacklist)
                    neighbor_label = labels[neighbor]
                    
                    if haskey(remaining, neighbor_label) && remaining[neighbor_label] > 0
                        # Prepare new state variables for the extended subgraph
                        new_remaining = copy(remaining)
                        new_remaining[neighbor_label] -= 1
                        
                        empty!(scratch)
                        union!(scratch, visited)
                        push!(scratch, neighbor)
                        
                        if scratch in seen_subgraphs
                            continue
                        end
                        
                        push!(seen_subgraphs, copy(scratch))
                        
                        new_subgraph = vcat(current_subgraph, [neighbor])
                        
                        push!(queue, (new_subgraph, copy(scratch), new_remaining))
                    end
                end
            end
        end
    end
    
    return collect(all_subgraphs)
end

# Example usage
g = SimpleGraph(10)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 5)
add_edge!(g, 1, 6)
add_edge!(g, 6, 7)
add_edge!(g, 2, 8)
add_edge!(g, 3, 9)
add_edge!(g, 3, 10)
add_edge!(g, 5, 1)

labels = ["A", "B", "A", "C", "D", "D", "C", "C", "B", "A"]
start_node = 2

all_subgraphs = find_all_subgraphs(g, start_node, Set{Int}(), labels, Dict("A" => 2, "B" => 1))

println(all_subgraphs)

@btime find_all_subgraphs(g, start_node, Set{Int}([3, 4]), labels, Dict("A" => 2, "B" => 1))

@profview [find_all_subgraphs(g, start_node, N, Set{Int}()) for _ in 1:10000]
@profview_allocs [find_all_subgraphs(g, start_node, N, Set{Int}()) for _ in 1:10000]