Maybe(T::Type) = Union{T,Nothing}

###################
### DATASETTYPE ###
###################

abstract type DatasetType end


### PonctualDataset ###
struct PonctualDataset <: DatasetType
    data::DataFrame
    target::Vector{Symbol}
end
function PonctualDataset(data, target ; keys::Vector{tK}=Symbol[]) where tK<:Union{String,Symbol}
    check_keys(names(data),keys)
    PonctualDataset(data, target)
end
PonctualDataset(data, target::Symbol) = PonctualDataset(data, [target])


### TimeseriesDataset ###
struct TimeseriesDataset <: DatasetType
    data::DataFrame
    target::Vector{Symbol}
    var::Symbol
end
function TimeseriesDataset(data, target, var ; keys::Vector{tK}=Symbol[]) where tK<:Union{String,Symbol}
    check_keys(names(data),keys)
    TimeseriesDataset(data, target, var)
end
TimeseriesDataset(data, target::Symbol, var) = TimeseriesDataset(data, [target], var)

# helper functions :
function group(ds::TimeseriesDataset)
    groupby(ds.data,ds.var)
end

function get_timeseries(tsds::TimeseriesDataset,val)
    df = tsds.data
    return TimeseriesDataset(df[df[:,tsds.var] .== val,:], tsds.target, tsds.var)
end


# ALL DATASETS :
Base.@kwdef struct Dataset
    ponctual::Vector{PonctualDataset} = PonctualDataset[]
    timeseries::Vector{TimeseriesDataset} = TimeseriesDataset[]
end
Dataset(tsd::Vector{TimeseriesDataset},pd::Vector{PonctualDataset}) = Dataset(pd,tsd)
Dataset(pd::PonctualDataset,tsd::TimeseriesDataset) = Dataset([pd],[tsd])
Dataset(pd::Vector{PonctualDataset},tsd::TimeseriesDataset) = Dataset(pd,[tsd])
Dataset(pd::PonctualDataset,tsd::Vector{TimeseriesDataset}) = Dataset([pd],tsd)


function check_keys(colnames::Vector{String},keys::Vector{tK}) where tK<:Union{String,Symbol}
    if !isempty(keys)
        isin = colnames .∈ Ref(string.(keys))
        id_notin = findall(.!isin)
        !isempty(id_notin) && throw(ArgumentError("column names $(colnames[id_notin]) are in keys argument"))
    end
end


export DatasetType, PonctualDataset, TimeseriesDataset, Dataset, group, get_timeseries