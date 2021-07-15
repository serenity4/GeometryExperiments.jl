abstract type Curve end

struct Patch{C<:Curve}
    curve::C
    n::Int
end

function (patch::Patch{C})(t, points) where {C}
    nₚ = length(points)
    n = patch.n
    ncurves = 1 + Int((nₚ - n) / 2)
    curve_offset = clamp(Int(t ÷ (1/ncurves)), 0, ncurves - 1)
    start = 1 + 2curve_offset
    remap = Scaling(ncurves) ∘ Translation(-curve_offset/ncurves)
    t = remap(Point(t))[]
    patch.curve(t, @view points[start:start+n-1])
end
