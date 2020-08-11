using GridapMakie
using Documenter

makedocs(;
    modules=[GridapMakie],
    authors="Francesc Verdugo <fverdugo@cimne.upc.edu> and contributors",
    repo="https://github.com/gridap/GridapMakie.jl/blob/{commit}{path}#L{line}",
    sitename="GridapMakie.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gridap.github.io/GridapMakie.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/gridap/GridapMakie.jl",
)
