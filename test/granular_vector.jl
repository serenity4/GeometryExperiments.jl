using GeometryExperiments: GranularVector, sprintc_mime
using Test

@testset "GranularVector" begin
  gvec = GranularVector{Int}()
  @test isempty(gvec)
  push!(gvec, 1, 2, 3)
  @test !isempty(gvec)
  @test gvec.nothing_count[] == 0
  @test gvec.current_hole[] == 0
  @test length(gvec) == 3
  @test collect(gvec) == [1, 2, 3]

  deleteat!(gvec, 2)
  @test length(gvec) == 2
  @test collect(gvec) == [1, 3]
  @test gvec.vec == [1, nothing, 3]
  @test gvec.nothing_count[] == 1

  push!(gvec, 4)
  @test length(gvec) == 3
  @test collect(gvec) == [1, 3, 4]
  @test gvec.vec == [1, nothing, 3, 4]
  @test gvec.nothing_count[] == 1

  push!(gvec, 5)
  deleteat!(gvec, 3)
  deleteat!(gvec, 4)
  @test gvec.nothing_count[] == 3
  @test gvec.vec == [1, nothing, nothing, nothing, 5]

  push!(gvec, 6)
  @test gvec.nothing_count[] == 2
  @test gvec.current_hole[] == 2
  @test gvec.vec == [1, 6, nothing, nothing, 5]
  @test collect(eachindex(gvec)) == [1, 2, 5]

  empty!(gvec)
  @test isempty(gvec.vec)
  @test gvec.nothing_count[] == 0
  @test gvec.current_hole[] == 0

  append!(gvec, [10, 11, 12])
  gvec[2] = 14
  @test gvec.vec == [10, 14, 12]

  @test isa(sprintc_mime(show, gvec), String)
end;
