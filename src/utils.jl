sprintc(f, args...; context = :color => true, kwargs...) = sprint((args...) -> f(args...; kwargs...), args...; context)
sprintc_mime(f, args...; kwargs...) = sprintc(f, MIME"text/plain"(), args...; kwargs...)
