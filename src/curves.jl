abstract type Curve end

struct Patch{C<:Curve}
    curve::C
    n::Int
end

function ncurves(patch::Patch, points)
    nₚ = length(points)
    1 + Int((nₚ - patch.n) / 2)
end

function (patch::Patch)(t, points)
    nc = ncurves(patch, points)
    curve_offset = clamp(Int(t ÷ (1/nc)), 0, nc - 1)
    remap = Scaling(nc) ∘ Translation(-curve_offset/nc)
    t = remap(Point(t))[]
    patch.curve(t, curve_points(patch, points, curve_offset))
end

startindex(patch::Patch, curve_offset) = 1 + (patch.n - 1) * curve_offset

function curve_points(patch::Patch, points, curve_offset=0)
    start = startindex(patch, curve_offset)
    @view points[start:start + patch.n - 1]
end

function Base.split(points, patch::Patch)
    nc = ncurves(patch, points)
    map(offset -> curve_points(patch, points, offset), 0:(nc - 1))
end
