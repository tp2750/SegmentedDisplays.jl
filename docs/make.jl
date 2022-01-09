using SegmentedDisplays
using Documenter
using Literate

Literate.markdown("docs/src/image_reading1.jl", "docs/src")
Literate.markdown("docs/src/digit_identification.jl", "docs/src")
Literate.markdown("docs/src/display_segmentation.jl", "docs/src")
Literate.markdown("docs/src/dashboard.jl", "docs/src")
Literate.markdown("docs/src/segmentation.jl", "docs/src")

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
        "Display Segmentation" => "display_segmentation.md",
        "Digit identification" => "digit_identification.md",
        "Image reading 1" => "image_reading1.md",
        "API v1 Segmentation" => "segmentation.md",
    ],
)

deploydocs(;
    repo="github.com/tp2750/SegmentedDisplays.jl",
    devbranch="main",
)
