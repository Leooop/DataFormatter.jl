import Base: length

Maybe(T::Type) = Union{T,Nothing}

###################
### DATASETTYPE ###
###################

abstract type DatasetType end

function group(ds::DatasetType ; rounding_digits=nothing)
    if !isnothing(rounding_digits) 
        @transform!(ds.data, {ds.group_on} = round({ds.group_on}, digits=rounding_digits))
    end
    return isnothing(ds.group_on) ? [ds.data] : groupby(ds.data,ds.group_on)
end

name(ds::DatasetType) = ds.name

function Base.show(io::IO, ds::DatasetType)
    print(io, typeof(ds) ," : ", name(ds), ", with target {",ds.target...,"} and grouped on ", ds.group_on, ", ", ds.data)
end
function Base.show(io::IO, ::MIME"text/plain", ds::DatasetType)
    println(io, typeof(ds), " :")
    println(io, "    -> name       : ", name(ds))
    println(io, "    -> target     : {", ds.target...,"}")
    println(io, "    -> grouped on :  ", ds.group_on)
    println(io, "    -> data       : ", ds.data)
end
### PonctualDataset ###
struct PonctualDataset <: DatasetType 
    name::String
    data::DataFrame
    target::Vector{Symbol}
    group_on::Union{Symbol,Nothing}
end
PonctualDataset(name, data, target::Symbol, group_on) = PonctualDataset(name, data, [target], group_on)
PonctualDataset(data, target, group_on) = PonctualDataset("ponctual_$(rand(1:999))", data, target, group_on)

Base.length(pd::PonctualDataset) = size(pd.data,1)

### TimeseriesDataset ###
struct TimeseriesDataset <: DatasetType
    name::String
    data::DataFrame
    target::Vector{Symbol}
    group_on::Union{Symbol,Nothing}
    function TimeseriesDataset(name,data,target,group_on)
        @assert ("t" ∈ names(data)) "time column :t is missing from data when constructing TimeseriesDataset"
        new(name,data,target,group_on)
    end
end
# function TimeseriesDataset(data, target, var ; keys::Vector{tK}=Symbol[]) where tK<:Union{String,Symbol}
#     check_keys(names(data),keys)
#     TimeseriesDataset(data, target, var)
# end
TimeseriesDataset(name, data, target::Symbol, group_on) = TimeseriesDataset(name, data, [target], group_on)
TimeseriesDataset(data, target, group_on) = TimeseriesDataset("timeseries_$(rand(1:999))", data, target, group_on)

function get_timeseries(tsds::TimeseriesDataset,val)
    df = tsds.data
    return TimeseriesDataset(df[df[:,tsds.group_on] .== val,:], tsds.target, tsds.group_on)
end

Base.length(ts::TimeseriesDataset) = size(ts.data,1)


# ALL DATASETS :
Base.@kwdef struct Dataset
    ponctual::Vector{PonctualDataset} = PonctualDataset[]
    timeseries::Vector{TimeseriesDataset} = TimeseriesDataset[]
    function Dataset(ponctual, timeseries)
        all_names = [name.(timeseries) ; name.(ponctual)]
        @assert (length(all_names) == length(unique(all_names))) "datasets names are not unique"
        new(ponctual, timeseries)
    end
end
Dataset(tsd::Vector{TimeseriesDataset},pd::Vector{PonctualDataset}) = Dataset(pd,tsd)
Dataset(pd::PonctualDataset,tsd::TimeseriesDataset) = Dataset([pd],[tsd])
Dataset(tsd::TimeseriesDataset,pd::PonctualDataset) = Dataset([pd],[tsd])
Dataset(pd::Vector{PonctualDataset},tsd::TimeseriesDataset) = Dataset(pd,[tsd])
Dataset(tsd::TimeseriesDataset, pd::Vector{PonctualDataset}) = Dataset(pd,[tsd])
Dataset(pd::PonctualDataset,tsd::Vector{TimeseriesDataset}) = Dataset([pd],tsd)
Dataset(tsd::Vector{TimeseriesDataset}, pd::PonctualDataset) = Dataset([pd],tsd)

# helpers
ndatasets(ds::Dataset) = length(ds.ponctual) + length(ds.timeseries)
Base.length(ds::Dataset) = sum(length(ds.ponctual)) + sum(length(ds.timeseries))
Base.names(ds::Dataset) = [name.(ds.timeseries) ; name.(ds.ponctual)]

function Base.getindex(ds::Dataset, targetname::String)
    for (i,ts_name) in enumerate(name.(ds.timeseries))
        (targetname == ts_name) && return ds.timeseries[i]
    end
    for (i,pd_name) in enumerate(name.(ds.ponctual))
        (targetname == pd_name) && return ds.ponctual[i]
    end
    throw(ArgumentError("unknown dataset name $targetname"))
end

export DatasetType, PonctualDataset, TimeseriesDataset, Dataset, group, get_timeseries, ndatasets, name