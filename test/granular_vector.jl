using GeometryExperiments: GranularVector, GranularVectorView, sprintc_mime, nextind!
using Test

test_nothingcount(gvec::GranularVector) = @test gvec.nothing_count[] == count(isnothing, gvec.vec)

@testset "GranularVector" begin
  gvec = GranularVector{Int}()
  @test isempty(gvec)
  @test nextind!(gvec) == 1
  push!(gvec, 1, 2, 3)
  @test !isempty(gvec)
  test_nothingcount(gvec)
  @test gvec.current_hole[] == 0
  @test length(gvec) == 3
  @test collect(gvec) == [1, 2, 3]

  deleteat!(gvec, 2)
  @test length(gvec) == 2
  @test collect(gvec) == [1, 3]
  @test gvec.vec == [1, nothing, 3]
  test_nothingcount(gvec)

  push!(gvec, 4)
  @test length(gvec) == 3
  @test collect(gvec) == [1, 3, 4]
  @test gvec.vec == [1, nothing, 3, 4]
  test_nothingcount(gvec)

  push!(gvec, 5)
  deleteat!(gvec, 3)
  deleteat!(gvec, 4)
  test_nothingcount(gvec)
  @test gvec.vec == [1, nothing, nothing, nothing, 5]

  push!(gvec, 6)
  test_nothingcount(gvec)
  @test gvec.current_hole[] == 2
  @test gvec.vec == [1, 6, nothing, nothing, 5]
  @test collect(eachindex(gvec)) == [1, 2, 5]

  empty!(gvec)
  @test isempty(gvec.vec)
  test_nothingcount(gvec)
  @test gvec.current_hole[] == 0

  append!(gvec, [10, 11, 12])
  gvec[2] = 14
  @test gvec.vec == [10, 14, 12]
  @test isa(sprintc_mime(show, gvec), String)
  v = view(gvec, [1, 3])
  @test isa(v, GranularVectorView)
  @test v[1] == 10
  @test v[2] == 12
  @test collect(v) == [10, 12]
  nc = gvec.nothing_count[]
  v[2] = 18
  @test gvec[3] == 18
  deleteat!(gvec, 3)
  @test collect(v) == [10]

  gvec = GranularVector([1, 2, 3])
  @test nextind!(gvec) == 4
  insert!(gvec, 10, 4)
  @test length(gvec.vec) == 10
  @test gvec.vec == [1, 2, 3, nothing, nothing, nothing, nothing, nothing, nothing, 4]
  test_nothingcount(gvec)
  @test nextind!(gvec) == 4
end;
