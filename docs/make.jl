using SatisFactoring
using Documenter

DocMeta.setdocmeta!(SatisFactoring, :DocTestSetup, :(using SatisFactoring); recursive=true)

makedocs(;
    modules=[SatisFactoring],
    authors="nzy1997",
    sitename="SatisFactoring.jl",
    format=Documenter.HTML(;
        canonical="https://nzy1997.github.io/SatisFactoring.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/nzy1997/SatisFactoring.jl",
    devbranch="main",
)
