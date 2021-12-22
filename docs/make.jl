using SegmentedDisplays
using Documenter
using Literate

Literate.markdown("src/dashboard.jl", "src")

DocMeta.setdocmeta!(SegmentedDisplays, :DocTestSetup, :(using SegmentedDisplays); recursive=true)

makedocs(;
    modules=[SegmentedDisplays],
    authors="Thomas Poulsen",
    repo="https://github.com/tp2750/SegmentedDisplays.jl/blob/{commit}{path}#{line}",
    sitename="SegmentedDisplays.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tp2750.github.io/SegmentedDisplays.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Dashboard" => "dashboard.md",
    ],
)

deploydocs(;
    repo="github.com/tp2750/SegmentedDisplays.jl",
    devbranch="main",
)
