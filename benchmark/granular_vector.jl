using GeometryExperiments: GranularVector

function make_vector_with_holes(n, nothing_ratio = 0.2)
  vec = Vector{Union{Nothing,Int64}}(undef, n)
  for i in 1:n
    if rand() < nothing_ratio
      vec[i] = nothing
    else
      vec[i] = rand(1:3)
    end
  end
  vec
end

vec = make_vector_with_holes(10000)
gvec = GranularVector(vec)
fvec = Iterators.Filter(!isnothing, vec)
ffvec = filter(!isnothing, vec)
iffvec = convert(Vector{Int}, ffvec)

using BenchmarkTools

@btime sum($iffvec)
@btime sum($ffvec)
@btime sum($gvec)
@btime sum($fvec)

@btime collect($iffvec)
@btime collect($ffvec)
@btime collect($gvec)
@btime collect($fvec)
