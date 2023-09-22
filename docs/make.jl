using Tangle
using Documenter

DocMeta.setdocmeta!(Tangle, :DocTestSetup, :(using Tangle); recursive=true)

makedocs(;
    modules=[Tangle],
    authors="MarkNahabedian <naha@mit.edu> and contributors",
    repo="https://github.com/MarkNahabedian/Tangle.jl/blob/{commit}{path}#{line}",
    sitename="Tangle.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MarkNahabedian.github.io/Tangle.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Examples" => Any[
            "Simple Example" => "examples/simple_chevron.md",
            "From an Image" => "examples/from_an_image.md",
            "Weaving Text" => "examples/text.md",
            "Nametags" => "examples/nametag.md"
        ]
    ],
)

deploydocs(;
    repo="github.com/MarkNahabedian/Tangle.jl",
    devbranch="main",
)
