rm("images", force=true, recursive=true)
mkpath("images")
module README; include("README.jl"); end
using Literate
Literate.markdown("README.jl", "..", documenter=false)

