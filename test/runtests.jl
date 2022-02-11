import DataFormatter as DF
using Test
using DataFrames


@testset "2 times series TimeseriesDataset" begin
    tsdf = DataFrame(:t=>rand(6),:y=>rand(6),:v=>[1,1,1,2,2,2])
    tsds = DF.TimeseriesDataset(tsdf,:v)
    ts_groups = DF.split_timeseries(tsds)
    @test length(ts_groups) == 2
end

@testset "1 times series TimeseriesDataset" begin
    tsdf = DataFrame(:t=>rand(6),:y=>rand(6),:v=>[1,1,1,1,1,1])
    tsds = DF.TimeseriesDataset(tsdf,:v)
    ts_groups = DF.split_timeseries(tsds)
    @test length(ts_groups) == 1
end

@testset "2 times series TimeseriesDataset with keys" begin
    tsdf = DataFrame(:t=>rand(6),:y=>rand(6),:v=>[1,1,1,1,1,1])
    keys = ["t","y","v"]
    keys2 = [:t,:y,:v]
    tsds = DF.TimeseriesDataset(tsdf, :v ; keys=keys)
    tsds = DF.TimeseriesDataset(tsdf, :v ; keys=keys2)
    
    ts_groups = DF.split_timeseries(tsds)
    @test length(ts_groups) == 1
end

@testset "colname not in keys" begin
    tsdf = DataFrame(:t=>rand(6),:y=>rand(6),:v=>[1,1,1,1,1,1])
    keys = ["t","y"]
    @test_throws ArgumentError DF.TimeseriesDataset(tsdf, :v ; keys=keys)
end