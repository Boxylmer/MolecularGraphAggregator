using Graphs
using BenchmarkTools
using DataStructures


function find_all_subgraphs(g::SimpleGraph, start_node::Int, N::Int, node_blacklist::Set{Int})
    all_subgraphs = Set{Vector{Int}}()
    
    # Initialize the queue with the start node and its subgraph
    queue = [([start_node], BitSet([start_node]))]
    
    while !isempty(queue)
        current_subgraph, visited = popfirst!(queue)
        
        if length(current_subgraph) == N
            push!(all_subgraphs, sort(current_subgraph))  # sort ensures uniqueness
            continue
        end
        
        for last_node in current_subgraph
            for neighbor in neighbors(g, last_node)
                if !(neighbor in visited) && !(neighbor in node_blacklist)
                    new_visited = union(visited, BitSet([neighbor]))
                    new_subgraph = vcat(current_subgraph, [neighbor])
                    
                    push!(queue, (new_subgraph, new_visited))
                end
            end
        end
    end
    
    return collect(all_subgraphs)
end

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
start_node = 5
N = 5
all_subgraphs = Set([g for g in find_all_subgraphs(g, start_node, N, )])
found = Set(([1, 2, 5, 6, 7], [1, 2, 3, 4, 5], [2, 3, 4, 5, 8], [1, 3, 4, 5, 6], [1, 2, 3, 5, 10], [1, 3, 4, 5, 9], [1, 4, 5, 6, 7], [3, 4, 5, 9, 10], [2, 3, 4, 5, 9], [1, 2, 4, 5, 8], [1, 2, 4, 5, 6], [1, 2, 3, 5, 8], [1, 2, 5, 6, 8], [1, 2, 3, 5, 6], [1, 3, 4, 5, 10], [1, 2, 3, 5, 9], [2, 3, 4, 5, 10]))
all_subgraphs == found


all_subgraphs = find_all_subgraphs(g, start_node, N, Set{Int}([4, 3]))

@btime find_all_subgraphs(g, start_node, N, Set{Int}([4, 3]))