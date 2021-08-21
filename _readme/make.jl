rm("images", force=true, recursive=true)
rm("models", force=true, recursive=true)
module README; include("README.jl"); end
using Literate
Literate.markdown("README.jl", "..", documenter=false)

