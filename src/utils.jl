sprintc(f, args...; context = :color => true, kwargs...) = sprint((args...) -> f(args...; kwargs...), args...; context)
sprintc_mime(f, args...; kwargs...) = sprintc(f, MIME"text/plain"(), args...; kwargs...)

struct Degree end
Base.:(*)(x, ::Degree) = deg2rad(x)
const ° = Degree()
