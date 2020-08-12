using GridapMakie
using Literate
using Documenter

# Literate
inputpath = joinpath(@__DIR__, "lit", "examples.jl")
outputdir = joinpath(@__DIR__, "src")
Literate.markdown(inputpath, outputdir)

makedocs(;
    modules=[GridapMakie],
    authors="Francesc Verdugo <fverdugo@cimne.upc.edu> and contributors",
    repo="https://github.com/gridap/GridapMakie.jl/blob/{commit}{path}#L{line}",
    sitename="GridapMakie.jl",
    doctest=false, # TODO
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gridap.github.io/GridapMakie.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Examples" => "examples.md",
    ],
)

deploydocs(
    repo = "github.com/jw3126/UnitfulRecipes.jl.git",
    push_preview = true
)
