abstract type PrimitiveAssembly end

struct TriangleStrip <: PrimitiveAssembly end

function connect(n, connec::TriangleStrip)
    n ≥ 3 || error("Cannot connect less than 3 vertices as triangle strips.")
    map(2:n-1) do i
        (i - 1, i + (i % 2), i + 2 - (i % 2))
    end
end
