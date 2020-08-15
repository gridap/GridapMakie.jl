using Literate
rm("images", force=true, recursive=true)
mkpath("images")
Literate.markdown("README.jl", "..")
module README; include("README.jl"); end

