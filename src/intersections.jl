in(p::Point, obj::NormedPrimitive) = obj(p) ≤ 0
in(p::Point, tr::Transformed) = tr(p) ≤ 0
