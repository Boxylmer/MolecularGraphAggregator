using Graphs
using BenchmarkTools
using DataStructures

function find_all_subgraphs(g::SimpleGraph, start_node::Int, N::Int, node_blacklist::Set{Int})
    all_subgraphs = Set{Vector{Int}}()
    scratch = BitSet()  # Pre-allocated "scratch" BitSet for those visited sets. This reduces allocs by like ~10% in most cases.
    
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
                    empty!(scratch)
                    union!(scratch, visited)
                    push!(scratch, neighbor)
                    
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

@btime find_all_subgraphs(g, start_node, N, Set{Int}([4, 3]))

@profview [find_all_subgraphs(g, start_node, N, Set{Int}()) for _ in 1:10000]
@profview_allocs [find_all_subgraphs(g, start_node, N, Set{Int}()) for _ in 1:10000]