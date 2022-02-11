
# plot PonctualDataset :
function vizualize(pds::PonctualDataset, series_var::Symbol, xys::Vararg{T,N}) where {T,N}
    dg = groupby(pds.data, series_var)
    colnames = names(pds.data)
    f = Figure()
    ax = Axis(f[1,1])
    for i in 1:length(dg)
        for j in eachindex(xys)
            idx = findfirst(colnames.== string(xys[j][1]))
            idy = findfirst(colnames.== string(xys[j][2]))
            scatter!(ax,-dg[i][:,idx], -dg[i][:,idy])
        end
    end
    f, ax 
end

export vizualize