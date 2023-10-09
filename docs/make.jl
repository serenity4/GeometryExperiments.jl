using GeometryExperiments
using Documenter

DocMeta.setdocmeta!(GeometryExperiments, :DocTestSetup, :(using GeometryExperiments); recursive = true)

makedocs(;
  modules = [GeometryExperiments],
  authors = "Cédric BELMANT",
  repo = "https://github.com/serenity4/GeometryExperiments.jl/blob/{commit}{path}#{line}",
  sitename = "GeometryExperiments.jl",
  format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", "false") == "true",
    canonical = "https://serenity4.github.io/GeometryExperiments.jl",
    edit_link = "main",
    assets = String[],
  ),
  pages = [
    "Home" => "index.md",
  ],
)

deploydocs(;
  repo = "github.com/serenity4/GeometryExperiments.jl",
  devbranch = "main",
)
