using Documenter, GridapMakie

makedocs(;
    modules=[GridapMakie],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/gridap/GridapMakie.jl/blob/{commit}{path}#L{line}",
    sitename="GridapMakie.jl",
    authors="The GridapMakie project contributors",
)

deploydocs(;
    repo="github.com/gridap/GridapMakie.jl",
)
