struct AtomTokenGraph
    graph::SimpleGraph
    nodemap::Vector{AtomToken}
end

function AtomTokenGraph(molecular_graph::SMILESMolGraph)
    g = SimpleGraph(molecular_graph.graph)
    atomtokens = collect(AtomTokenIterator(molecular_graph))
    
    return AtomTokenGraph(g, atomtokens)
end

Base.length(atg::AtomTokenGraph) = length(atg.nodemap)

# plot(AtomTokenGraph(mol).graph, curves=false)

# [println(edge) for edge in edges(AtomTokenGraph(mol).graph)]

