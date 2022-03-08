function get_target_data(ds::Dataset)
    df_target = DataFrame([:target, :target_sim, :std, :target_name] .=> [Float64[], Float64[], Float64[], Symbol[]])
    for i in 1:length(ds.ponctual)
        append!(df_target, get_target_data(ds.ponctual[i]))
        #mat_target = [mat_target ; Matrix{Float64}(get_target_data(ds.ponctual[i]))]
    end
    for i in 1:length(ds.timeseries)
        #mat_target = [mat_target ; Matrix{Float64}(get_target_data(ds.timeseries[i]))]
        append!(df_target,get_target_data(ds.timeseries[i]))
    end
    return df_target
end

function get_target_data(ds::DatasetType)
    df = ds.data
    target = ds.target
    sim_target = @. string(target)*"_sim" |> Symbol
    valid_rows = .!ismissing.(df[!,sim_target[1]])
    df_target = copy(df[valid_rows, [target..., sim_target..., :std]])
    df_target.target_name = fill(target...,nrow(df_target))
    rename!(df_target,[:target, :target_sim, :std, :target_name])
    return df_target
end

export get_target_data