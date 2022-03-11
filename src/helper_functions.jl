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
    std_target = @. "std_"*string(target) |> Symbol
    valid_rows = get_valid_rows(ds)
    df_target = copy(df[valid_rows, [target[1], sim_target[1], std_target[1]]])
    insertcols!(df_target, (:target_name=>fill(target[1],nrow(df_target))))
    rename!(df_target,[:target, :target_sim, :std, :target_name])
    for i in 2:length(target)
        df_target_i = df[valid_rows, [target[i], sim_target[i], std_target[i]]]
        insertcols!(df_target_i, (:target_name=>fill(target[i],nrow(df_target_i))))
        rename!(df_target_i,[:target, :target_sim, :std, :target_name])
        append!(df_target, df_target_i)
    end
    return df_target
end

function get_valid_rows(ds::DatasetType)
    df = ds.data
    target = ds.target
    sim_target = @. string(target)*"_sim" |> Symbol
    valid_rows_vec = [.!ismissing.(df[!,sim_target[i]]) for i in eachindex(sim_target)]
    intersect = valid_rows_vec[1]
    for i in eachindex(intersect)
        for iv in 2:length(valid_rows_vec)
            intersect[i] = intersect[i] & valid_rows_vec[iv][i]
        end
    end
    return intersect
end

export get_target_data