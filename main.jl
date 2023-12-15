using Graphs
using MolecularGraph
# using GraphNeuralNetworks
using StaticArrays

using BenchmarkTools
using Random


include("utils.jl")

include("smiles_examples.jl")

include("AtomToken.jl")

include("AtomTokenGraph.jl")

include("GroupToken.jl")

# include("GroupTokenSearch.jl")

function parse_smiles(smiles::AbstractString)
    mol = smilestomol(smiles)
    add_hydrogens!(mol)
    return mol
end

found_tokens = new_token_dict()
for smile in smiles
    discover_tokens!(found_tokens, parse_smiles(smile))
end
collect(println(tok) for tok in found_tokens)

smiles = [
    "C1=CC=C2C(=C1)C=CC(=O)O2"
    "CC1=NOC=C1"
    "C1=CON=C1"
    "C1=CC=C2C(=C1)C=CO2"
    "C1=COC(=C1)C=O"
    "C1=COC(=C1)C#N"
]
for smile in smiles
    mol = smilestomol(smile)
    hybs = hybridization(mol)
    as = atomsymbol(mol)
    ar = is_aromatic(mol)
    for i in eachindex(hybs, as, ar)
        if hybs[i] == :sp3 && as[i] == :O && ar[i]
            println(smile)
            break
        end
    end
end

atgs = AtomTokenGraph.(parse_smiles.(smiles))


atom = atgs[1].nodemap[1]
atom_token_string(value(atom))
uint16val = value(atom)
v = Int64(uint16val)
atom_token_string(uint16val)

tokens = search_linear_group_tokens.(atgs, 3)
master_token_set = union(tokens...)

tokens = search_linear_group_tokens.(atgs, 1)
remainder_tokens = union(tokens...)
@btime tokens = (search_linear_group_tokens(atgs[1], 2))
 
# test matching
testtoken = LinearGroupToken(0x0264, 0x0264, 0x0068)
@btime map_token(atgs[4], testtoken, 12; randomsearch=true)

@btime map_token(atgs[4], testtoken, 12; randomsearch=true, searchable_nodes=BitSet([1, 2, 3, 4, 6, 11, 12, 13]))

using Plots
using GraphRecipes
graphplot(atgs[4].graph, names = [string(i, " - ", atgs[4].nodemap[i]) for i in eachindex(atgs[4].nodemap)])



completely_map_atg(atgs[4], master_token_set, remainder_tokens)
# found_tokens = new_token_dict()
# discover_tokens!(found_tokens, smilestomol(smiles[1]))
# found_tokens
# tokens[1] == tokens[5]


# edge case, symmetric tokens
testtoken2 = LinearGroupToken([0x0068, 0x0259, 0x0068]) # ... I think for now this is fine...
for atg in atgs
    println(map_token(atg, testtoken2, 100; randomsearch=true))
end


@btime get_mapping_cache(atgs[4], master_token_set)


gen = LinearGroupTokenGraphGenerator(atgs[4], master_token_set, remainder_tokens)

randomg = randomgraph(gen)
graphplot(randomg.graph, names = [string(randomg.nodes[i]) for i in eachindex(randomg.nodes)], fontsize=3)


generators = [LinearGroupTokenGraphGenerator(atg, master_token_set, remainder_tokens) for atg in atgs]
@btime [randomgraph(generators[rand(1:length(generators))]) for _ in 1:1000]