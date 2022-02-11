module DataFormatter

using DataFrames: DataFrame, groupby, Not, insertcols!

include("types.jl")
include("simulation.jl")
include("vizualize.jl")

end
