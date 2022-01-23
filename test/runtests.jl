using SegmentedDisplays
using Test

@testset "SegmentedDisplays.jl" begin
    @test SegmentedDisplays.segment_midpoint([[1,2],[1,4]]) == [1,3]
    @test SegmentedDisplays.segment_midpoint([[1,2],[3,2]]) == [2,2]
end
