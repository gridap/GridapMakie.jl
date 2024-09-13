# Remove current directories:
rm("images", force=true, recursive=true)
rm("models", force=true, recursive=true)

module README; include("README.jl"); end

# Create README.md with a preprocessor to update version-dependent url's
using Literate, Makie, Pkg

# Get Makie version:
const Makie_version = Pkg.TOML.parsefile(joinpath(pkgdir(Makie), "Project.toml"))["version"]

# Dictionary of URL's to replace on the go:
const READMETAG2URL = Dict{String, String}(
"Observables_url" => "http://makie.juliaplots.org/v"*Makie_version*"/documentation/nodes/index.html"
)

# Replace README tags by actual url's:
function update_url(content)
    for (READMETAG, URL) in READMETAG2URL
        content = replace(content, READMETAG=>URL)
    end
    content
end

Literate.markdown("README.jl", ".."; preprocess=update_url, documenter=false)