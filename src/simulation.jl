

function simulate!(dataset::Dataset, p)
    simulate!.(dataset.ponctual,Ref(p))
    simulate!.(dataset.timeseries, Ref(p))
end

##################################
### SIMULATE PONCTUAL DATASETS ###
##################################

function simulate!(pds::PonctualDataset, p)
    data = pds.data
    for i in 1:nrow(data)
        data_params = data[i,Not(pds.target)] # Dataframerow without target variable
        df_sol = p.f.ponctual(p, data_params, pds.target) 
        (i == 1) && insert_sim_cols!(pds, names(df_sol))
        data[i,sol_colnames] .= df_sol[1,!]
    end
    return nothing
end

####################################
### SIMULATE TIMESERIES DATASETS ###
####################################

function simulate!(tsds::TimeseriesDataset, p)
    data = tsds.data
    gdata = groupby(data,tsds.var)
    for i in 1:length(gdata)
        data_params = gdata[i][1,Not([tsds.target ; :t])] # Dataframerow without target variable
        df_sol = p.f.timeseries(p, data_params, tsds.target, gdata[i].t) # 
        sol_colnames = names(df_sol)
        (i == 1) && insert_sim_cols!(tsds, sol_colnames)
        gdata[i][1:size(df_sol,1),sol_colnames] .= df_sol[:,sol_colnames]
    end
    return nothing
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

export simulate!