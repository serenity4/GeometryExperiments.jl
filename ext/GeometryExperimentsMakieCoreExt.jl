module GeometryExperimentsMakieCoreExt

using MakieCore
using GeometryExperiments

import MakieCore: plottype, convert_arguments

plottype(::Curve) = Lines

convert_arguments(T::Type{<:Lines}, segment::Segment) = convert_arguments(T, [segment.a, segment.b])

convert_arguments(T::Type{<:Lines}, curve::Curve) = convert_arguments(T, curve.(0:0.01:1))
convert_arguments(T::Type{<:Lines}, line::Line) = convert_arguments(T, line.((-100:100)))
convert_arguments(T::Type{<:Scatter}, curve::Curve) = convert_arguments(T, collect(curve.points))

end
