using Graphs
using BenchmarkTools
using DataStructures

function find_all_subgraphs(g::SimpleGraph, start_node::Int, N::Int, node_blacklist::Set{Int})
    all_subgraphs = Set{Vector{Int}}()
    seen_subgraphs = Set{BitSet}() 
    scratch = BitSet()
    
    start_visited = BitSet([start_node])
    push!(seen_subgraphs, start_visited)
    
    queue = [([start_node], start_visited)]
    
    while !isempty(queue)
        current_subgraph, visited = popfirst!(queue)
        
        if length(current_subgraph) == N
            push!(all_subgraphs, (current_subgraph))
            continue
        end
        
        for last_node in current_subgraph
            for neighbor in neighbors(g, last_node)
                if !(neighbor in visited) && !(neighbor in node_blacklist)
                    empty!(scratch)
                    union!(scratch, visited)
                    push!(scratch, neighbor)
                    
                    if scratch in seen_subgraphs
                        continue
                    end
                    push!(seen_subgraphs, copy(scratch))
                    
                    new_subgraph = vcat(current_subgraph, [neighbor])
                    
                    push!(queue, (new_subgraph, copy(scratch)))
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
all_subgraphs = find_all_subgraphs(g, start_node, N, Set{Int}([4, 3]))

@btime find_all_subgraphs(g, start_node, N, Set{Int}([3, 4]))

@profview [find_all_subgraphs(g, start_node, N, Set{Int}()) for _ in 1:10000]
@profview_allocs [find_all_subgraphs(g, start_node, N, Set{Int}()) for _ in 1:10000]