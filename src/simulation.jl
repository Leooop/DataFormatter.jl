using LinearAlgebra

function simulate!(dataset::Dataset, p ; allow_mismatch=false)
    simulate!.(dataset.ponctual,Ref(p))
    simulate!.(dataset.timeseries, Ref(p) ; allow_mismatch)
    nothing
end


#################################
## SIMULATE PONCTUAL DATASETS ###
#################################

function simulate!(pds::PonctualDataset, p ; allow_mismatch=false)
    data = pds.data
    for i in 1:size(data,1)
        data_params = data[i,Not(pds.target)] # Dataframerow without target variable
        df_sol::DataFrame = p.f.ponctual(p, data_params, pds.target)
        sol_colnames::Vector{String} = names(df_sol)
        (i == 1) && insert_sim_cols!(pds, sol_colnames)
        allow_mismatch && throw(error("allow_mismatch kwarg must be false"))
        for sol_colname in sol_colnames
            data[i,sol_colname] = df_sol[1,sol_colname]
        end
    end
    return nothing
end

####################################
### SIMULATE TIMESERIES DATASETS ###
####################################

function simulate!(tsds::TimeseriesDataset, p ; allow_mismatch=false) 
    data = tsds.data
    gdata = group(tsds)
    for i in 1:length(gdata)
        data_params = gdata[i][1,Not([tsds.target ; :t])] # Dataframerow without target variable
        sim_data = p.f.timeseries(p, data_params, tsds.target, gdata[i].t)
        (i==1) && set_clean_sim_cols!(data, sim_data)
        check_matching_times!(gdata[i], sim_data, allow_mismatch)
        merge_sim_data!(gdata[i],sim_data)
    end
    return nothing
end


function merge_sim_data!(data,sim_data)
    colnames_sim = names(sim_data)
    sim_length = size(sim_data,1)
    for simname in colnames_sim
        if occursin("_sim", simname)
            @views data[1:sim_length,simname] .= sim_data[1:sim_length,simname]
            @views data[sim_length+1:end,simname] .= missing
        end
    end
    return data
end

function check_matching_times!(data,sim_data,allow_mismatch)
    # if data.t != sim_data.t
    #     @show data.t
    #     @show sim_data.t
    # end
    if allow_mismatch
        for i in eachindex(sim_data.t)
            @assert sim_data.t[i] == data.t[i]
        end
    else
        @assert all(data.t .== sim_data.t)
    end
end

function set_clean_sim_cols!(data, sim_data)
    colnames = names(data)
    colnames_sim = names(sim_data)
    eltypesim = eltype(sim_data[:,filter(!=("t"), colnames_sim)[1]])
    for simname in colnames_sim
        if occursin("_sim", simname)
            #@transform!(data,$simname = missing)
            if (simname ∈ colnames) && (eltypesim <: eltype(data[!,simname]))
                fill!(data[!,simname],missing)
            else
                data[!,simname] = Vector{Union{eltypesim,Missing}}(undef,size(data,1))
                fill!(data[!,simname],missing)
            end
        end
    end
    return data
end

### HELPER ###
function insert_sim_cols!(ds::DatasetType, sim_colnames)
    colnames = names(ds.data)
    for i in 1:length(sim_colnames)
        if string(sim_colnames[i]) ∉ colnames
            insertcols!(ds.data, last(names(ds.data)), 
                sim_colnames[i] => Vector{Union{Missing,Float64}}(missing,size(ds.data,1)), 
                after=true)
        end
    end
end

get_data_covmat(target_df::AbstractDataFrame) = Diagonal(target_df.std)

g(m, p, ds::Union{Dataset,DatasetType}) = (p.mp .= m ; simulate!(ds,p) ; get_target_data(ds).target_sim)

export simulate!, get_data_covmat, g